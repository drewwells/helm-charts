{{- define "spire-server.podSpec" }}
{{- $fullname := include "spire-server.fullname" . }}
{{- with .Values.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
serviceAccountName: {{ include "spire-server.serviceAccountName" . }}
shareProcessNamespace: true
securityContext:
  {{- toYaml .Values.podSecurityContext | nindent 2 }}
{{- if gt (len .Values.initContainers) 0 }}
initContainers:
  {{- toYaml .Values.initContainers | nindent 2 }}
{{- end }}
containers:
  - name: {{ .Chart.Name }}
    securityContext:
      {{- toYaml .Values.securityContext | nindent 6 }}
    image: {{ template "spire-lib.image" (dict "appVersion" $.Chart.AppVersion "image" .Values.image "global" .Values.global) }}
    imagePullPolicy: {{ .Values.image.pullPolicy }}
    args:
      - -expandEnv
      - -config
      - /run/spire/config/server.conf
    env:
    - name: PATH
      value: "/opt/spire/bin:/bin"
    {{- if ne .Values.dataStore.sql.databaseType "sqlite3" }}
    - name: DBPW
      valueFrom:
        secretKeyRef:
          name: {{ $fullname }}-dbpw
          key: DBPW
    {{- end }}
    ports:
      - name: grpc
        containerPort: 8081
        protocol: TCP
      - containerPort: 8080
        name: healthz
      {{- with .Values.federation }}
      {{- if eq (.enabled | toString) "true" }}
      - name: federation
        containerPort: {{ .bundleEndpoint.port }}
        protocol: TCP
      {{- end }}
      {{- end }}
      {{- if (dig "telemetry" "prometheus" "enabled" .Values.telemetry.prometheus.enabled .Values.global) }}
      - containerPort: 9988
        name: prom
      {{- end }}
    livenessProbe:
      httpGet:
        path: /live
        port: healthz
      failureThreshold: 2
      initialDelaySeconds: 15
      periodSeconds: 60
      timeoutSeconds: 3
    readinessProbe:
      httpGet:
        path: /ready
        port: healthz
      initialDelaySeconds: 5
      periodSeconds: 5
    resources:
      {{- toYaml .Values.resources | nindent 6 }}
    volumeMounts:
      - name: spire-server-socket
        mountPath: /tmp/spire-server/private
        readOnly: false
      - name: spire-config
        mountPath: /run/spire/config
        readOnly: true
      {{- if eq (.Values.persistence.enabled | toString) "true" }}
      - name: spire-data
        mountPath: /run/spire/data
        readOnly: false
      {{- end }}
      {{- if eq (.Values.upstreamAuthority.disk.enabled | toString) "true" }}
      - name: upstream-ca
        mountPath: /run/spire/upstream_ca
        readOnly: false
      {{ end }}
      {{- if gt (len .Values.extraVolumeMounts) 0 }}
      {{- toYaml .Values.extraVolumeMounts | nindent 6 }}
      {{- end }}
  {{- if eq (.Values.controllerManager.enabled | toString) "true" }}
  - name: spire-controller-manager
    securityContext:
      {{- toYaml .Values.controllerManager.securityContext | nindent 6 }}
    image: {{ template "spire-lib.image" (dict "appVersion" $.Chart.AppVersion "image" .Values.controllerManager.image "global" .Values.global) }}
    imagePullPolicy: {{ .Values.controllerManager.image.pullPolicy }}
    args:
      - --config=controller-manager-config.yaml
    ports:
      - name: https
        containerPort: 9443
        protocol: TCP
      - containerPort: 8083
        name: healthz
      {{- if (dig "telemetry" "prometheus" "enabled" .Values.telemetry.prometheus.enabled .Values.global) }}
      - containerPort: 8082
        name: prom2
      {{- end }}
    livenessProbe:
      httpGet:
        path: /healthz
        port: healthz
    readinessProbe:
      httpGet:
        path: /readyz
        port: healthz
    resources:
      {{- toYaml .Values.controllerManager.resources | nindent 6 }}
    volumeMounts:
      - name: spire-server-socket
        mountPath: /tmp/spire-server/private
        readOnly: true
      - name: controller-manager-config
        mountPath: /controller-manager-config.yaml
        subPath: controller-manager-config.yaml
        readOnly: true
      - name: spire-controller-manager-tmp
        mountPath: /tmp
        readOnly: false
  {{- end }}
  {{- if gt (len .Values.extraContainers) 0 }}
  {{- toYaml .Values.extraContainers | nindent 2 }}
  {{- end }}
{{- with .Values.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.affinity }}
affinity:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.topologySpreadConstraints }}
topologySpreadConstraints:
  {{- toYaml . | nindent 2 }}
{{- end }}
volumes:
  - name: spire-config
    configMap:
      name: {{ include "spire-server.fullname" . }}
  - name: spire-server-socket
    emptyDir: {}
  - name: spire-controller-manager-tmp
    emptyDir: {}
  {{- if eq (.Values.upstreamAuthority.disk.enabled | toString) "true" }}
  - name: upstream-ca
    secret:
      secretName: {{ include "spire-server.upstream-ca-secret" . }}
  {{- end }}
  {{- if eq (.Values.controllerManager.enabled | toString) "true" }}
  - name: controller-manager-config
    configMap:
      name: {{ include "spire-controller-manager.fullname" . }}
  {{- end }}
  {{- if gt (len .Values.extraVolumes) 0 }}
  {{- toYaml .Values.extraVolumes | nindent 2 }}
  {{- end }}
{{- end }}
