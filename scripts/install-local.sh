# install gogs 

#!/bin/bash

echo "###############################################################################"
echo "#  MAKE SURE YOU ARE LOGGED IN:                                               #"
echo "#  $ oc login http://console.your.openshift.com                               #"
echo "###############################################################################"

function usage() {
    echo
    echo "Usage:"
    echo " $0 [command] [options]"
    echo " $0 --help"
    echo
    echo "Example:"
    echo " $0  --project-suffix mydemo"
    echo
    echo 
    echo "OPTIONS:"
    echo "   --user [username]          Optional    The admin user for the demo projects. Required if logged in as system:admin"
    echo "   --project-suffix [suffix]  Optional    Suffix to be added to demo project names e.g. ci-SUFFIX. If empty, user will be used as suffix"
    echo "   --ephemeral                Optional    Deploy demo without persistent storage. Default false"
    echo "   --oc-options               Optional    oc client options to pass to all oc commands e.g. --server https://my.openshift.com"
    echo
}

ARG_USERNAME=
ARG_PROJECT_SUFFIX=
ARG_COMMAND=
ARG_EPHEMERAL=false
ARG_OC_OPS=
ARG_PRIVATE=false

while :; do
    case $1 in
        deploy)
            ARG_COMMAND=deploy
            ;;
        delete)
            ARG_COMMAND=delete
            ;;    
        --user)
            if [ -n "$2" ]; then
                ARG_USERNAME=$2
                shift
            else
                printf 'ERROR: "--user" requires a non-empty value.\n' >&2
                usage
                exit 255
            fi
            ;;
        --project-suffix)
            if [ -n "$2" ]; then
                ARG_PROJECT_SUFFIX=$2
                shift
            else
                printf 'ERROR: "--project-suffix" requires a non-empty value.\n' >&2
                usage
                exit 255
            fi
            ;;
        --oc-options)
            if [ -n "$2" ]; then
                ARG_OC_OPS=$2
                shift
            else
                printf 'ERROR: "--oc-options" requires a non-empty value.\n' >&2
                usage
                exit 255
            fi
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            break
            ;;
        -?*)
            printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
            shift
            ;;
        *) # Default case: If no more options then break out of the loop.
            break
    esac

    shift
done


LOGGEDIN_USER=$(oc $ARG_OC_OPS whoami)
OPENSHIFT_USER=${ARG_USERNAME:-$LOGGEDIN_USER}
PRJ_SUFFIX=${ARG_PROJECT_SUFFIX:-`echo $OPENSHIFT_USER | sed -e 's/[-@].*//g'`}
GITHUB_ACCOUNT=${GITHUB_ACCOUNT:-gbengataylor}
GITHUB_REF=${GITHUB_REF:-ocp-4.3}
REPO_NAME=${REPO_NAME:-openshift-cd-demo-va}

GOGS_NAMESPACE=gogs-$PRJ_SUFFIX

sleep 1

function deploy() {

    oc $ARG_OC_OPS new-project $GOGS_NAMESPACE --display-name="Gogs"

    # hack to get hostname
    oc new-app jenkins-ephemeral
    HOSTNAME=$(oc get route jenkins -n $GOGS_NAMESPACE -o template --template='{{.spec.host}}' | sed "s/jenkins-${GOGS_NAMESPACE}.//g")
    GOGS_HOSTNAME="gogs-$GOGS_NAMESPACE.$HOSTNAME"

    oc new-app -f templates/gogs-template-ephemeral.yaml  \
        --param=GOGS_VERSION=0.11.34 \
        --param=DATABASE_VERSION=9.6 \
        --param=HOSTNAME=$GOGS_HOSTNAME \
        --param=SKIP_TLS_VERIFY=true

    GOGS_SVC=$(oc get route gogs -o template --template='{{.spec.host}}')
    GOGS_USER=gogs
    GOGS_PWD=gogs

    oc rollout status dc gogs

    # Even though the rollout is complete gogs isn't always ready to create the admin user
    sleep 10

    # Try 10 times to create the admin user. Fail after that.
    for i in {1..10};
    do

        _RETURN=$(curl -o /tmp/curl.log -sL --post302 -w "%{http_code}" http://$GOGS_SVC/user/sign_up \
        --form user_name=$GOGS_USER \
        --form password=$GOGS_PWD \
        --form retype=$GOGS_PWD \
        --form email=admin@gogs.com)

        if [ $_RETURN == "200" ] || [ $_RETURN == "302" ]
        then
        echo "SUCCESS: Created gogs admin user"
        break
        elif [ $_RETURN != "200" ] && [ $_RETURN != "302" ] && [ $i == 10 ]; then
        echo "ERROR: Failed to create Gogs admin"
        cat /tmp/curl.log
        exit 255
        fi

        # Sleep between each attempt
        sleep 10

    done 

    # curl      
    _RETURN=$(curl -o /tmp/curl.log -sL -w "%{http_code}" -H "Content-Type: application/json" \
    -H 'Accept:application/json' -u $GOGS_USER:$GOGS_PWD -X POST http://$GOGS_SVC/api/v1/user/repos -d @data.json)

    if [ $_RETURN != "201" ] ;then
        echo "ERROR: Failed to import openshift-tasks GitHub repo"
        cat /tmp/curl.log
        exit 255
    fi

    #create repo
    mkdir -p gogs/$REPO_NAME/templates
    cp templates/* gogs/$REPO_NAME/templates
    pushd gogs/$REPO_NAME
    git init
    git add *
    git commit -m "commit"
    git remote add origin http://$GOGS_SVC/$GOGS_USER/$REPO_NAME.git

    echo "pushing to gogs, you might be asked for credentials"
    echo "enter $GOGS_USER for user and $GOGS_PWD for password"
    git push -u origin master

    popd
    rm -rf gogs
    #remove jenkins
    oc delete all -lapp=jenkins-ephemeral
}

function delete() {
    oc $ARG_OC_OPS delete project $GOGS_NAMESPACE
}

#MAIN COMMAND

case "$ARG_COMMAND" in
    delete)
        echo "Delete demo..."
        delete
        echo
        echo "Delete completed successfully!"
        ;;
    deploy)
        echo "Deploying demo..."
        deploy
        echo
        echo "Provisioning completed successfully!"
        ;;
        
    *)
        echo "Invalid command specified: '$ARG_COMMAND'"
        usage
        ;;
esac