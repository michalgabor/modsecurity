# WAF based on ModSecurity

Based on docker image https://github.com/fareoffice/modsecurity-docker

Please use "3.0.2" tag on "fareoffice/modsecurity" image: "fareoffice/modsecurity:3.0.2"  
We shall keep image versioned according to version of Core Rule Set (CRS) it includes.

## Bootstrap

In your `deploy.yaml` add following

```
apiVersion: v1
kind: DeploymentConfig
metadata:
  name: security
spec:
  replicas: 1
  strategy:
    type: Rolling
  template:
    metadata:
      labels:
        name: security
    spec:
      containers:
      - name: modsecurity-proxy
        image: fareoffice/modsecurity:3.0.2
        imagePullPolicy: Always
        env:
        - name: PROXY_UPSTREAM_HOST
          value: "my-service"
        ports:
          - containerPort: 80
        livenessProbe:
          tcpSocket:
            port: 80
          initialDelaySeconds: 10
          timeoutSeconds: 10
---
apiVersion: v1
kind: Service
metadata:
  name: security-service
spec:
  selector:
    name: security
  ports:
    - port: 80
      targetPort: 80
      protocol: TCP
```

Adjust **PROXY_UPSTREAM_HOST** env var accordingly, it shall point to your service.

Make sure **Route** points to "security-service", not to "my-service"

```
apiVersion: v1
kind: Route
metadata:
  name: my-route
  labels:
    router: external
spec:
  host: ${NAMESPACE}-${CLUSTER}.fareonline.net
  to:
    kind: Service
    name: security-service
  tls:
    insecureEdgeTerminationPolicy: Redirect
    termination: edge
```

## Understand Paranoia levels

The Paranoia Level (PL) setting allows you to choose the desired level of rule checks.

With each paranoia level increase, the CRS enables additional rules
giving you a higher level of security. However, higher paranoia levels
also increase the possibility of blocking some legitimate traffic due to
false alarms (also named false positives or FPs). If you use higher
paranoia levels, it is likely that you will need to add some exclusion
rules for certain requests and applications receiving complex input.

Paranoia level 3 is default on **fareoffice/modsecurity**.  
You can adjust it with **PARANOIA** env var; see below for full list of adjustable env vars.

- **Paranoia level of 1**. In this level, most core rules are enabled.
  PL1 is advised for beginners, installations
  covering many different sites and applications, and for setups
  with standard security requirements.
  At PL1 you should face FPs rarely. If you encounter FPs, please
  open an issue on the CRS GitHub site and don't forget to attach your
  complete Audit Log record for the request with the issue.
- **Paranoia level 2** includes many extra rules, for instance enabling
  many regexp-based SQL and XSS injection protections, and adding
  extra keywords checked for code injections. PL2 is advised
  for moderate to experienced users desiring more complete coverage
  and for installations with elevated security requirements.
  PL2 comes with some FPs which you need to handle.
- **Paranoia level 3** enables more rules and keyword lists, and tweaks
  limits on special characters used. PL3 is aimed at users experienced
  at the handling of FPs and at installations with a high security
  requirement.
- **Paranoia level 4** further restricts special characters.
  The highest level is advised for experienced users protecting
  installations with very high security requirements. Running PL4 will
  likely produce a very high number of FPs which have to be
  treated before the site can go productive.

Source: https://github.com/SpiderLabs/owasp-modsecurity-crs/blob/v3.0/master/crs-setup.conf.example#L130


## Adjust Rules and Engine behviour

You may need adjust modsecurity default rules, can do that by setting env vars starting with:

- **SEC_RULE_BEFORE_**  
  these rules execute *before* any default rules, control rule engine behaviour here  
  Rules will be added to following file in the container  
  `/etc/httpd/modsecurity.d/owasp-crs/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf`  
  See also https://github.com/SpiderLabs/owasp-modsecurity-crs/blob/v3.0/master/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example
- **SEC_RULE_AFTER_**  
  these rules execute *after* any default rules, edit existing rules here  
  Rules will be added to following file in the container  
  `/etc/httpd/modsecurity.d/owasp-crs/rules/REQUEST-999-EXCLUSION-RULES-AFTER-CRS.conf`  
  See also https://github.com/SpiderLabs/owasp-modsecurity-crs/blob/v3.0/master/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf.example

Example (these are for Watto, also having keycloak-proxy behind modsecurity-proxy)
```
- name: SEC_RULE_AFTER_DISABLE_COOKIE_KC_ACCESS # this cookie is safe but so big and has special chars, so drives modsec nuts
  value: "SecRuleUpdateTargetById 900000-999999 !REQUEST_COOKIES:/^kc-access/"
- name: SEC_RULE_AFTER_DISABLE_951   # 951 is SQL Injection check that fails on PRCE Limit, spitting many irrelevant warnings
  value: "SecRuleRemoveById 951000-951999"
```

See also https://github.com/SpiderLabs/ModSecurity/wiki/Reference-Manual

## Full list of env vars

- **PARANOIA** = 3  
  see above
- **SEC_RULE_ENGINE** = On  
  Possible values: On / Off / DetectionOnly
- **PROXY_UPSTREAM_HOST** = localhost:3000  
  Target to forward incoming traffic to, use your service name there; default value plays nicely with keycloak-proxy behind
- **SEC_PRCE_MATCH_LIMIT** = 500000  
  you may want adjust this to fight PRCE Limit errors, also see below.
- **SEC_PRCE_MATCH_LIMIT_RECURSION** = 500000  
  you may want adjust this to fight PRCE Limit errors.  
  The PCRE Match limit is meant to reduce the chance for a DoS attack via Regular Expressions.
  So by raising the limit you raise your vulnerability in this regard, 
  but the PCRE errors are much worse from a security perspective.
- **SEC_RULE_BEFORE_<FREE_TEXT_HERE>**  
  see above
- **SEC_RULE_AFTER_<TYPE_ANYTHING_YOU_LIKE_AS_LONG_AS_ITS_UNIQUE>**  
  see above

## ModSecurity + KeycloakProxy

Example
```
apiVersion: v1
kind: DeploymentConfig
metadata:
  name: security
spec:
  replicas: 1
  strategy:
    type: Rolling
  template:
    metadata:
      labels:
        name: security
    spec:
      containers:
      - name: modsecurity-proxy
        image: fareoffice/modsecurity:3.0.2
        imagePullPolicy: Always
        env:
        - name: SEC_RULE_AFTER_DISABLE_COOKIE_KC_ACCESS # this cookie is safe but so big and has special chars, so drives modsec nuts
          value: "SecRuleUpdateTargetById 900000-999999 !REQUEST_COOKIES:/^kc-access/"
        ports:
          - containerPort: 80
        livenessProbe:
          tcpSocket:
            port: 80
          initialDelaySeconds: 10
          timeoutSeconds: 10
      - name: keycloak-proxy
        image: quay.io/gambol99/keycloak-proxy:v2.1.1
        imagePullPolicy: Always
        envFrom:
        - secretRef:
            name: vault-cluster
            optional: false
        - secretRef:
            name: vault-namespace
            optional: false
        args:
        - --listen=0.0.0.0:3000
        - --discovery-url=${SECURITY_KEYCLOAK_DISCOVERY_URL}
        - --client-id=${SECURITY_KEYCLOAK_CLIENT_ID}
        - --client-secret=${SECURITY_KEYCLOAK_CLIENT_SECRET}
        - --resources=uri=/*|roles=app:user
        - --enable-logging
        - --verbose=true
        - --upstream-url=http://app-service
        ports:
          - containerPort: 3000
            protocol: TCP
        livenessProbe:
          tcpSocket:
            port: 3000
          initialDelaySeconds: 10
          timeoutSeconds: 10

---

apiVersion: v1
kind: Route
metadata:
  name: app-route
  labels:
    router: external
spec:
  host: ${NAMESPACE}-${CLUSTER}.fareonline.net
  to:
    kind: Service
    name: security-service
  tls:
    insecureEdgeTerminationPolicy: Redirect
    termination: edge

---

apiVersion: v1
kind: Service
metadata:
  name: app-service
spec:
  selector:
    name: app
  ports:
    - port: 80
      targetPort: 8080
      protocol: TCP

---

apiVersion: v1
kind: Service
metadata:
  name: security-service
spec:
  selector:
    name: security
  ports:
    - port: 80
      targetPort: 80
      protocol: TCP
```
