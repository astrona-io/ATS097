# Summary

Sealed Secrets moves the encryption key into the cluster. This module installed the controller with Flux, sealed a Secret and followed the key through its life.

## What you learned

The controller owns an RSA key pair and decrypts `SealedSecret` objects into Secrets with the same name and namespace, and owns the Secrets it creates. `kubeseal` encrypts with the controller's public certificate, which can be fetched once and used offline. Flux applies the `SealedSecret` as an ordinary manifest and needs no decryption setting. A sealed file works for one cluster only.

The scope sets what must match at decryption: the name and namespace for strict, the namespace for namespace-wide, nothing for cluster-wide. Strict is the default and the safest. The controller refuses to take over a Secret that already exists and is not its own. Decryption errors appear in the status and events of the `SealedSecret`.

The controller renews its key every 30 days by default and keeps old keys. The key Secrets, found by the label `sealedsecrets.bitnami.com/sealed-secrets-key`, must be backed up outside Git and outside the cluster, because losing them loses every sealed value. Compared with SOPS, Sealed Secrets is simpler for one cluster and Secrets only, while SOPS suits many clusters, key services and other file types. The key facts to remember are these:

- Flux applies the object. The controller decrypts it.
- Strict scope binds a value to a name and namespace.
- Back up the key Secrets.
- A renewed key does not protect old files.

<!-- astrona:playground:destroy -->
