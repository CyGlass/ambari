# Curl Utility for Ambari

`acurl` is a `curl` based utility called `acurl` that provides a simple script interface to Ambari. Copy the `configure.sh` [script from here](https://github.com/CyGlass/ambari/tree/branch-2.7-cyglass/ambari-server/src/main/cyglass/acurl), and use it like this:

```bash
$ ./configure.sh 
please specify ENDPOINT (e.g. http://ambari-node-dev:8080/api/v1)
usage: configure.sh <ENDPOINT> <USERNAME> [PASSWORD]

$ ./configure.sh http://ambari-node-dev:8080/api/v1 admin admin
acurl is configured, source the session.rc file into your shell to continue

$ . session.rc 
acurl is now ready to use:
  acurl <document path> [CURL ARGUMENTS]

$ acurl clusters
{
  "href": "http://ambari-node-dev:8080/api/v1/clusters",
  "items": [
    {
      "href": "http://ambari-node-dev:8080/api/v1/clusters/geek",
      "Clusters": {
        "cluster_name": "geek"
      }
    }
  ]
}
```



