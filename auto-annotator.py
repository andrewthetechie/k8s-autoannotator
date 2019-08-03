import logging
import os
from kubernetes import client, config

CLUSTER_FDQN = os.environ.get("CLUSTER_FQDN")

def add_dns(service):
    if service.metadata.annotations is None:
        dns_name = f"{service.metadata.name}.{CLUSTER_FDQN}"

    # specified an altname
    if 'external-dns.alpha.kubernetes.io/altname' in service.metadata.annotations:
        logging.debug("Service named %s has an altname of %s supplied", service.metadata.name,
                      service.metadata.annotations['external-dns.alpha.kubernetes.io/altname'])
        dns_name = f"{service.metadata.service.metadata.annotations['external-dns.alpha.kubernetes.io/altname']}." \
            f"{CLUSTER_FDQN}"


    patch = {'metadata' : {'annotations': {'external-dns.alpha.kubernetes.io/hostname': dns_name}}}
    config.load_incluster_config()
    v1 = client.CoreV1Api()
    logging.debug(v1.patch_namespaced_service(name=service.metadata.name,
                                              namespace=service.metadata.namespace,
                                              body=patch))

def main():

    logger = logging.getLogger()
    handler = logging.StreamHandler()
    formatter = logging.Formatter(
        '%(asctime)s %(name)-12s %(levelname)-8s %(message)s')
    handler.setFormatter(formatter)
    logger.addHandler(handler)
    logger.setLevel(logging.DEBUG)
    # it works only if this script is run by K8s as a POD
    config.load_incluster_config()

    v1 = client.CoreV1Api()
    # get all services
    for service in v1.list_service_for_all_namespaces(watch=False).items:
        # only looking at loadbalancers
        if service.spec.type == 'LoadBalancer':
            # check if we have an annotation already
            if service.metadata.annotations is None:
                # no annotations at all, lets add it
                logger.debug("Adding DNS for service named %s", service.metadata.name)
                add_dns(service)
            if not 'external-dns.alpha.kubernetes.io/hostname' in service.metadata.annotations:
                logger.debug("Service %s does not have dns setup", service.metadata.name)
                # if we've set nodns annotation, don't setup annotation
                if 'external-dns.alpha.kubernetes.io/nodns' in service.metadata.annotations and \
                        service.metadata.annotations['external-dns.alpha.kubernetes.io/nodns']:
                        logging.debug("Service named %s has nodns annotation set", service.metadata.name)
                        continue


            else:
                logger.debug("Service %s has DNS at %s", service.metadata.name,
                      service.metadata.annotations['external-dns.alpha.kubernetes.io/hostname'])


if __name__ == '__main__':
    main()