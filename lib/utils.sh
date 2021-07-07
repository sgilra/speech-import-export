# minio

get_mc(){
    DIST_DIR=$1
    if [ ! -d "${DIST_DIR}" ] ; then
        echo "no such directory: ${DIST_DIR}" >&2
        echo "failed to download mc" >&2
        exit 1
    fi

    ARC="amd64"
    MC_URL="https://dl.min.io/client/mc/release/linux-${ARC}/archive/mc.RELEASE.2020-11-17T00-39-14Z"

    echo "Getting minio client: ${MC_URL}"
    curl -skL "${MC_URL}" -o ${DIST_DIR}/mc
    chmod +x ${DIST_DIR}/mc
}

get_cpdbr(){
    DIST_DIR=$1
    if [ ! -d "${DIST_DIR}" ] ; then
        echo "no such directory: ${DIST_DIR}" >&2
        echo "failed to download cpdbr" >&2
        exit 1
    fi
    #TODO: replace with publically-available path
    wget http://icpfs1.svl.ibm.com/zen/cp4d-builds/4.0.0/dev/utils/cpdbr/latest/lib/linux/cpdbr -P ${DIST_DIR}
    chmod +x ${DIST_DIR}/cpdbr

}

start_minio_port_forward(){
    mkdir ./${TMP_FILENAME}
    touch ./${TMP_FILENAME}/keep_minio_port_forward
    trap "rm -f ./${TMP_FILENAME}/keep_minio_port_forward" 0 1 2 3 15
    keep_minio_port_forward &
    sleep 5
}

keep_minio_port_forward(){
    while [ -e ./${TMP_FILENAME}/keep_minio_port_forward ]
    do
        kubectl ${KUBECTL_ARGS} port-forward svc/${MINIO_SVC} ${MINIO_LPORT}:${MINIO_PORT} > /dev/null &
        PORT_FORWARD_PID=$!
        echo "PORT_FORWARD_PID: $PORT_FORWARD_PID"
        while [ -e ./${TMP_FILENAME}/keep_minio_port_forward ] && kill -0 ${PORT_FORWARD_PID} &> /dev/null
        do
            sleep 5
        done
    done
    if kill -0 ${PORT_FORWARD_PID} &> /dev/null ; then
        kill ${PORT_FORWARD_PID}
    fi
}

stop_minio_port_forward(){
    rm -rf ./${TMP_FILENAME}
    trap 0 1 2 3 15
    sleep 5
}
