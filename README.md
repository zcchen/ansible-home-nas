Home NAS Ansible Scripts
========================================

This project aims to setup a NAS server by different Open-Source projects with `ansible` script.


How to use
----------------------------------------
Execute the playbook script.
```
ansible-playbook -i inventory/ playbook.yml                 # execute all tasks
ansible-playbook -i inventory/ playbook.yml --tags <xxx>    # execute only the tasks under tag xxx
```



What may Include and Exclude?
----------------------------------------
+ Includings:
  1. The `docker-compose` project as the NAS server.
  2. The `docker` environment settings (incl. proxy setup if defined.)
+ Excludings:
  1. `DNS` settings to query this NAS server.
  2. The method to expose this NAS server to public, like reverse proxy settings.
  3. The proxy settings.


Project Scenarios & Principles
----------------------------------------
### Scenario
1. It is a project for home-lab or similar

### Principles
1. **Server should NOT be touched by non-administrators.**
 + If someone can touch it physically, services might be down and the data might be caught directly.
2. **Convenience is higher priority than safety paradigms.**
   One of the safety paradigms is NOT to save any passwords in plain on computer / server without any portal.
   But in this project, some passwords should be in plain for convenient configuration.
   Therefore, keep obeying **rule 1** and trust your administrator (or to be the administrator).


Based Concepts
----------------------------------------
1. Use multiple `docker-compose.yml` feature to generate the based project.
 + Container is the best technology for the based service concepts.
 + `k8s` is too heavy to learn and config.
 + `docker run` (or `podman run`) is too difficult to manage.
 + `docker compose` (or similar `podman` command) is just enough.

2. Target file structure
```
/nas/                   # the base dir, able to be modify on ansible inventory config
+- docker-compose.*.yml # the multiple docker-compose.yml config file, one catalog one file.
+- *.sh                 # the script file for this project.
+- docker/              # the base docker dirs for self-build docker images.
|  +- <service-name>    # the docker image dir.
+- conf/                # the base config dir for service containers.
|  +- <service-name>    # the config dir for specified service
+- env/                 # the env file for this project.
+- secrets/             # the secret files for this project.
+- data/                # the base runtime data dir for service containers. Usually, here is a disk mountpoint
|  +- <service-name>    # the runtime data dir for specified service
+- backup/              # the backup data dir for service containers. Usually, here is another disk mountpoint
   +- nas/              # the based file backup, including dirs and files under '/nas' dir, except 'data/' & 'backup/' dirs
   |  +- nas.tar.gz     # the based file backup tar file, nested under a dir for easier file increasement archeve
   +- data/             # the data file backup.
      +- <service-name> # the backup file for specified services.
/lib/systemd/system/nas.service     # the systemd service file for this project.
```

3. 


Service Structure
----------------------------------------
```
+---------------------------------------------------------------------------+   +-----------+
|                Nginx (docker-compose network: rev-proxy)                  |   |           |
+---------------------------------------------------------------------------+   |           |
       |                    |                   |                   |           |           |
+---------------+   +---------------+   +---------------+   +---------------+   |           |
|      Auth     |   |      File     |   |     Photo     |   |   Download    |   |           |
|    Service    |   |    Service    |   |    Service    |   |    Service    |   |  Backup   |
|   Front-End   |   |   Front-End   |   |   Front-End   |   |   Front-End   |   |  Service  |
|(OIDC Provider)|   |               |   |               |   |               |   |           |
+---------------+   +---------------+   +---------------+   +---------------+   |           |
|      Auth     |   |      File     |   |     Photo     |   |    Download   |   |           |
|   Background  |   |   Background  |   |   Background  |   |   Background  |   |           |
|    Services   |   |    Services   |   |    Services   |   |    Services   |   |           |
|   (OpenLDAP)  |   |               |   |               |   |               |   +-----------+
|               |   |               |   |               |   |               |  /      |
+---------------+   +---------------+   +---------------+   +---------------+ /       v
       |                    |                   |                   |        /  +-----------+
+---------------------------------------------------------------------------+   |   Backup  |
|   Local Files (Personal + Home Sharing) + Samba Sharing Big Files (home)  |   |   Files   |
+---------------------------------------------------------------------------+   +-----------+
```

### How to Select the services?

1. **Single Point to Manage Users**
   Single Signin Point is very important, because I don't want to manage the user & password everywhere.

2. **`Samba` is Great but `Samba AD DC` is too heavy**
   Many devices support `samba` sharing, but `LDAPSam` is no longer supported, replaced by `Samba AD DC`.
   `Samba AD DC` has too many useless services (e.g. `Kerbose`, internal `DNS`, ...) for home NAS.
   Therefore, I have to limit the `samba` service to handle limited parts (**home sharing files**) with public usernames & passwords.

3. **`LLDAP` is more friendly than `OpenLDAP`, but `OpenLDAP` template is OK**
   `LLDAP` is one of the most lightweight LDAP services, and it is more friendly than `OpenLDAP`, but it limits more.
   `OpenLDAP` docker image is much easier to extend the functions what I want.

4. **File Service Selection**
   File Services should have the following features:
   + `Webdav` supports.
   + Able to integrate with `OnlyOffice` or similar ones.
   + Mobile Apps supports: browser files, sync files (esp. `photos`) from phones.
   + (Better, alternative is `rclone`) has its computer apps to cache and upload files.
   -> `Nextclould` / `Owncloud` might be the best solution. (**NOT Testing**)

5. **Photo Service Selection**
   -> `PhotoPrism` might be the best solution. (**NOT Testing**, esp at originals read-only importing for multi users)

### How to Handle Password Reset.

