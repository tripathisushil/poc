echo "Configuring cluster to use a custom hostname and certificate..."

echo "Step 1 - checking all the pre-reqs"

echo "Checking for an authenticated oc CLI..."
TOKENS=$(oc whoami >/dev/null 2>&1)
if [ $? -eq 1 ]
then
  echo "You must be logged in with oc first"
  exit 1
else
  echo "Authenticated oc CLI found"
fi

echo "Checking for a CP4I_NAMESPACE environment variable..."
if [ -z "${CP4I_NAMESPACE}" ]
then
  echo "No CP4I_NAMESPACE environment variable set"
  echo "This is needed to locate the installation of CP4I on the cluster"
  exit 1
else
  echo "Found CP4I namespace: ${CP4I_NAMESPACE}"
fi

echo "Checking for a CS_NAMESPACE environment variable..."
if [ -z "${CS_NAMESPACE}" ]
then
  echo "No CS_NAMESPACE environment variable set"
  echo "This is needed to locate the installation of Common Services on the cluster"
  exit 1
else
  echo "Found Common Services namespace: ${CS_NAMESPACE}"
fi

echo "Checking for tls.crt..."
if [ ! -f "./tls.crt" ]
then
  echo "No tls.crt found"
  echo "Please put the TLS certificate in tls.crt in the current directory"
  exit 1
else
  echo "Found tls.crt"
fi

echo "Checking for tls.key..."
if [ ! -f "./tls.key" ]
then
  echo "No tls.key found"
  echo "Please put the TLS key in tls.key in the current directory"
  exit 1
else
  echo "Found tls.key"
fi

echo "Checking for ca.crt..."
if [ ! -f "./ca.crt" ]
then
  echo "No ca.crt found"
  echo "Please put the CA public certificate in ca.crt in the current directory"
  exit 1
else
  echo "Found ca.crt"
fi

echo "Checking for a CP4I_HOSTNAME environment variable..."
if [ -z "${CP4I_HOSTNAME}" ]
then
  echo "No CP4I_HOSTNAME environment variable set"
  echo "This must be valid against the provided certificate"
  exit 1
else
  echo "Found hostname: ${CP4I_HOSTNAME}"
fi

echo "Looking for the CP4I route..."
ZEN_ROUTE=$(oc get route cpd -n ${CP4I_NAMESPACE} -o jsonpath="{.spec.host}")
if [ -z "${ZEN_ROUTE}" ]
then
  echo "No CP4I route found"
  exit 1
else
  echo "Found CP4I at https://${ZEN_ROUTE}"
fi

echo "Step 2 - updating the CP4I route"

echo "Creating external-tls-secret with the given certificate information..."
oc -n ${CP4I_NAMESPACE} delete secret external-tls-secret
oc -n ${CP4I_NAMESPACE} create secret generic external-tls-secret --from-file=ca.crt=ca.crt  --from-file=cert.crt=tls.crt  --from-file=cert.key=tls.key

echo "Updating the UI configuration to use the external-tls-secret secret for TLS..."
oc patch -n ${CP4I_NAMESPACE} automationuiconfig iaf-system --type merge --patch '{"spec": {"tls": {"certificateSecret": {"secretName": "external-tls-secret"}}}}'

echo "Updating the host name in the CP4I route..."
oc patch -n ${CP4I_NAMESPACE} route cpd -p "{\"spec\":{\"host\":\"${CP4I_HOSTNAME}\"}}"

echo "Updating the host name in the product configmap..."
oc patch -n ${CP4I_NAMESPACE} configmap product-configmap -p "{\"data\":{\"URL_PREFIX\":\"${CP4I_HOSTNAME}\"}}"

echo "Updating the SSO client registration..."
oc patch -n ${CP4I_NAMESPACE} client zenclient-${CP4I_NAMESPACE} --type merge --patch "{\"spec\":{\"zenProductNameUrl\":\"https://${CP4I_HOSTNAME}/v1/preauth/config\",\"oidcLibertyClient\":{\"post_logout_redirect_uris\":[\"https://${CP4I_HOSTNAME}/auth/doLogout\"],\"redirect_uris\":[\"https://${CP4I_HOSTNAME}/auth/login/oidc/callback\"],\"trusted_uri_prefixes\":[\"https://${CP4I_HOSTNAME}\"]}}}"

echo "Restarting the nginx pods..."
oc delete pod -n ${CP4I_NAMESPACE} -l component=ibm-nginx

echo "Updating the oidc config in the usermgmt pods..."
oc -n ${CP4I_NAMESPACE} cp $(oc get pod -n ${CP4I_NAMESPACE} -l component=usermgmt | tail -1 | cut -f1 -d\ ):/user-home/_global_/config/oidc/oidcConfig.json oidcConfig.json
sed -i'' "s#https://.*/auth/login/oidc/callback#https://${CP4I_HOSTNAME}/auth/login/oidc/callback#" oidcConfig.json
oc -n ${CP4I_NAMESPACE} cp oidcConfig.json $(oc get pod -n ${CP4I_NAMESPACE} -l component=usermgmt | tail -1 | cut -f1 -d\ ):/user-home/_global_/config/oidc/
rm oidcConfig.json

echo "Restarting the usermgmt pods..."
oc delete pod -n ${CP4I_NAMESPACE} -l component=usermgmt

echo "Step 3 - updating the common services route"

echo "Taking ownership of the certificate away from common services"
oc -n ${CS_NAMESPACE} patch managementingress default --type merge --patch '{"spec":{"ignoreRouteCert":true}}'

echo "Updating certificate..."
oc -n ${CS_NAMESPACE} delete certificates.certmanager.k8s.io route-cert
oc -n ${CS_NAMESPACE} delete secret route-tls-secret
oc -n ${CS_NAMESPACE} create secret generic route-tls-secret --from-file=ca.crt=ca.crt  --from-file=tls.crt=tls.crt  --from-file=tls.key=tls.key

echo "Deleting ibmcloud-cluster-ca-cert to trigger a certificate refresh..."
oc delete secret ibmcloud-cluster-ca-cert -n ${CS_NAMESPACE}

echo "Restarting the auth-idp pods..."
oc -n ${CS_NAMESPACE} delete pod -l app=auth-idp

echo "Deleting the management-ingress-ibmcloud-cluster-ca-cert secret..."
oc -n ${CP4I_NAMESPACE} delete secret management-ingress-ibmcloud-cluster-ca-cert

echo "Creating a new operand request that will trigger the recreation of the management-ingress secret..."
oc apply -f operand_request.yaml

echo "Wait for the operand request to be ready..."
oc wait --for condition=ready --timeout=120s operandrequest -n ${CP4I_NAMESPACE} register-new-ca-cert

CURRENT_CARTRIDGE_ROUTE="https://${ZEN_ROUTE}"

echo "Restarting the ibm zen operator to update the cartridge object"
oc delete pod -n ${CS_NAMESPACE} -l name=ibm-zen-operator

echo "Checking integration cartidge has updated"
COUNTER=0
while [[ $COUNTER -lt 10 ]]; do
    CARTRIDGE_ENDPOINT=$(oc get cartridge integration -n ${CP4I_NAMESPACE} -o jsonpath='{.status.components.ui.endpoints[0].uri}')
    if [[ $CARTRIDGE_ENDPOINT != $CURRENT_CARTRIDGE_ROUTE ]]; then
      echo "Cartridge updated"
      break
    else
      echo "Waiting for integration cartridge to update"
    fi
sleep 60
((COUNTER+=1))
done

echo "Restarting the PN deployment pod..."
oc delete pods -l app.kubernetes.io/name=ibm-integration-platform-navigator

echo "Waiting for up to 30 minutes for the nginx pods, auth-idp pods and PN deployment pods to restart..."
oc wait --for condition=ready --timeout=900s pod -l component=ibm-nginx -n ${CP4I_NAMESPACE}
oc wait --for condition=ready --timeout=900s pod -l app=auth-idp -n ${CS_NAMESPACE}
oc wait --for condition=ready --timeout=900s pod -l app.kubernetes.io/name=ibm-integration-platform-navigator -n ${CP4I_NAMESPACE}

echo "Deleting the operand request now secret is up..."
oc delete operandrequest -n ${CP4I_NAMESPACE} register-new-ca-cert

echo "Setup complete"
echo "You can access CP4I at https://${CP4I_HOSTNAME}"
