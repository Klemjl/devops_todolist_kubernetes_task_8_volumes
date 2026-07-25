# Validation Instructions

These steps assume the cluster has been created with `cluster.yml` (e.g. `kind create cluster --config cluster.yml`) and that all manifests have been applied via `bash bootstrap.sh` from inside this directory.

## 1. Verify the app is running

Check that the namespace, pods, deployment, and HPA are healthy:

```bash
kubectl -n todoapp get pods
kubectl -n todoapp get deployment todoapp
kubectl -n todoapp get hpa todoapp
```

You should see the `todoapp` pod(s) in `Running` state with `READY 1/1`, and the deployment showing the desired number of replicas available.

Confirm the app responds to HTTP requests via the NodePort service (port `30007`, as mapped in `cluster.yml`):

```bash
curl http://localhost:30007/api/health
curl http://localhost:30007/api/ready
```

Both endpoints should return a successful (2xx) response.

You can also reach the app through the ClusterIP service from inside the cluster:

```bash
kubectl -n todoapp run curl-test --rm -it --image=curlimages/curl --restart=Never -- curl http://todoapp-service.todoapp.svc.cluster.local/api/health
```

## 2. Verify the ConfigMap is mounted as a file (read-only)

Exec into the running pod and confirm the `/app/configs` folder exists, is read-only, and contains a file per ConfigMap key:

```bash
POD=$(kubectl -n todoapp get pod -l app=todoapp -o jsonpath='{.items[0].metadata.name}')

kubectl -n todoapp exec "$POD" -- ls -la /app/configs
kubectl -n todoapp exec "$POD" -- cat /app/configs/PYTHONUNBUFFERED
```

You should see a file named `PYTHONUNBUFFERED` inside `/app/configs` whose content matches the value defined in `confgiMap.yml` (`1`). Confirm read-only enforcement:

```bash
kubectl -n todoapp exec "$POD" -- sh -c "echo test > /app/configs/PYTHONUNBUFFERED"
```

This command should fail with a "Read-only file system" error.

## 3. Verify the Secret is mounted as a file (read-only)

Confirm `/app/secrets` exists and contains a file for the secret key, and that its decoded content matches the value stored in `secret.yml`:

```bash
kubectl -n todoapp exec "$POD" -- ls -la /app/secrets
kubectl -n todoapp exec "$POD" -- cat /app/secrets/SECRET_KEY
```

Compare this output against the locally decoded secret value:

```bash
echo "QGUyKHl4KXYmdGdoM19zPTB5amEtaSFkcGVieHN6XmRnNDd4KS1rJmtxXzN6Zio5ZSoK" | base64 -d
```

The two values should match. As with the ConfigMap mount, confirm it is read-only:

```bash
kubectl -n todoapp exec "$POD" -- sh -c "echo test > /app/secrets/SECRET_KEY"
```

This should also fail with a "Read-only file system" error.

## 4. (Optional) Verify persistent storage

Confirm the PV and PVC are bound, and that the deployment is using the claim:

```bash
kubectl get pv todoapp-pv
kubectl -n todoapp get pvc todoapp-pvc
kubectl -n todoapp describe pod "$POD" | grep -A5 Mounts
```

The PV and PVC should both show status `Bound`, and `/app/data` should be listed among the pod's mounted volumes.