#!/usr/bin/env bash

DOCKERHUB_REPO=$1
# MVN_VERSION=$2
BASE_IMG_JRE_DEFAULT=$2
BASE_IMG_JRE_ARM32V7=$3
BASE_IMG_JRE_ARM64V8=$4

ACTIVEMQ_VERSION=5.15.9
CONSUL_VERSION=1.7.0
COUCHDB_VERSION=2.3.1
INFLUXDB_VERSION=1.7
KAFKA_VERSION=2.2.0
ZK_VERSION=3.4.13

cp_qemu() {
	cp /usr/bin/{qemu-arm-static,qemu-aarch64-static} $1
}

docker_build_push() {
	SERVICE=$1
	VERSION=$2
	IMG_NAME_DEFAULT=$DOCKERHUB_REPO/$SERVICE:$VERSION
	IMG_NAME_AMD64=$DOCKERHUB_REPO/$SERVICE:amd64-$VERSION
	IMG_NAME_ARM32V7=$DOCKERHUB_REPO/$SERVICE:arm32v7-$VERSION
	IMG_NAME_ARM64V8=$DOCKERHUB_REPO/$SERVICE:arm64v8-$VERSION

	# build docker images
	docker build --pull --build-arg BASE_IMG=$BASE_IMG_JRE_DEFAULT -t $IMG_NAME_DEFAULT -t $IMG_NAME_AMD64 -f $SERVICE/Dockerfile $SERVICE
	docker build --pull --build-arg BASE_IMG=$BASE_IMG_JRE_ARM32V7 -t $IMG_NAME_ARM32V7 -f $SERVICE/arm.Dockerfile $SERVICE
	docker build --pull --build-arg BASE_IMG=$BASE_IMG_JRE_ARM64V8 -t $IMG_NAME_ARM64V8 -f $SERVICE/aarch64.Dockerfile $SERVICE

	# push docker images
	docker push $IMG_NAME_DEFAULT
	docker push $IMG_NAME_AMD64
	docker push $IMG_NAME_ARM32V7
	docker push $IMG_NAME_ARM64V8

	# create manifest and push
	docker manifest create $IMG_NAME_DEFAULT $IMG_NAME_AMD64 $IMG_NAME_ARM32V7 $IMG_NAME_ARM64V8
	docker manifest annotate $IMG_NAME_DEFAULT $IMG_NAME_ARM32V7 --os linux --arch arm
	docker manifest annotate $IMG_NAME_DEFAULT $IMG_NAME_ARM64V8 --os linux --arch arm64
	docker manifest push $IMG_NAME_DEFAULT
}

docker_build_push_multiarch_existing() {
	SERVICE=$1
	VERSION=$2
	IMG_NAME_DEFAULT=$DOCKERHUB_REPO/$SERVICE:$VERSION
	IMG_NAME_AMD64=$DOCKERHUB_REPO/$SERVICE:amd64-$VERSION
	IMG_NAME_ARM32V7=$DOCKERHUB_REPO/$SERVICE:arm32v7-$VERSION
	IMG_NAME_ARM64V8=$DOCKERHUB_REPO/$SERVICE:arm64v8-$VERSION

	# build docker images
	docker build --pull --build-arg BASE_IMG=$BASE_IMG_JRE_DEFAULT --build-arg ARCH=amd64 -t $IMG_NAME_DEFAULT -t $IMG_NAME_AMD64 -f $SERVICE/Dockerfile $SERVICE
	docker build --pull --build-arg BASE_IMG=$BASE_IMG_JRE_ARM32V7 --build-arg ARCH=arm -t $IMG_NAME_ARM32V7 -f $SERVICE/Dockerfile $SERVICE
	docker build --pull --build-arg BASE_IMG=$BASE_IMG_JRE_ARM64V8 --build-arg ARCH=arm64 -t $IMG_NAME_ARM64V8 -f $SERVICE/Dockerfile $SERVICE

	# push docker images
	docker push $IMG_NAME_DEFAULT
	docker push $IMG_NAME_AMD64
	docker push $IMG_NAME_ARM32V7
	docker push $IMG_NAME_ARM64V8

	# create manifest and push
	docker manifest create $IMG_NAME_DEFAULT $IMG_NAME_AMD64 $IMG_NAME_ARM32V7 $IMG_NAME_ARM64V8
	docker manifest annotate $IMG_NAME_DEFAULT $IMG_NAME_ARM32V7 --os linux --arch arm
	docker manifest annotate $IMG_NAME_DEFAULT $IMG_NAME_ARM64V8 --os linux --arch arm64
	docker manifest push $IMG_NAME_DEFAULT
}



array=( activemq consul couchdb influxdb kafka zookeeper )
for i in "${array[@]}"
do
	echo "======> Building Docker Image: [ $i ]"

  if [ "$i" == "activemq" ]; then
		cp_qemu $i
		docker_build_push $i $ACTIVEMQ_VERSION

  elif [ "$i" == "consul" ]; then
		cp_qemu $i
		docker_build_push_multiarch_existing $i $CONSUL_VERSION

  elif [ "$i" == "couchdb" ]; then
		cp_qemu $i
		docker_build_push $i $COUCHDB_VERSION

  elif [ "$i" == "influxdb" ]; then
		cp_qemu $i
		docker_build_push_multiarch_existing $i $INFLUXDB_VERSION

  elif [ "$i" == "kafka" ]; then
		cp_qemu $i
		docker_build_push $i $KAFKA_VERSION

  elif [ "$i" == "zookeeper" ]; then
		cp_qemu $i
		docker_build_push $i $ZK_VERSION
  fi

done
