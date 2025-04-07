#!/bin/bash

cd /home/ec2-user/app
LOG_FILE="/home/ec2-user/deploy.log"
DOCKER_APP_NAME="spring"

# 로그 시작
echo "배포 시작일자 : $(date '+%Y-%m-%d %H:%M:%S')" >> $LOG_FILE

# redis, mysql이 꺼져있다면 기동
RUNNING_REDIS=$(sudo docker ps | grep redis)
RUNNING_MYSQL=$(sudo docker ps | grep mysql)

if [ -z "$RUNNING_REDIS" ]; then
  echo "Redis 실행" >> $LOG_FILE
  sudo docker-compose -p ${DOCKER_APP_NAME} -f docker-compose.yml up -d redis
fi

if [ -z "$RUNNING_MYSQL" ]; then
  echo "MySQL 실행" >> $LOG_FILE
  sudo docker-compose -p ${DOCKER_APP_NAME} -f docker-compose.yml up -d mysql
fi

# 현재 실행 중인 컨테이너 확인
EXIST_BLUE=$(sudo docker ps | grep couponmoa-blue)

if [ -z "$EXIST_BLUE" ]; then
  # blue가 비어있으면 blue 기동 → green 중단
  echo "blue 배포 시작 : $(date '+%Y-%m-%d %H:%M:%S')" >> $LOG_FILE
  sudo docker-compose -p ${DOCKER_APP_NAME} -f docker-compose.yml up -d --build app-blue

  sleep 30

  echo "green 중단 시작 : $(date '+%Y-%m-%d %H:%M:%S')" >> $LOG_FILE
  sudo docker stop couponmoa-green
  sudo docker rm couponmoa-green
  sudo docker image prune -af

  echo "green 중단 완료 : $(date '+%Y-%m-%d %H:%M:%S')" >> $LOG_FILE

else
  # blue가 실행 중이면 green 기동 → blue 중단
  echo "green 배포 시작 : $(date '+%Y-%m-%d %H:%M:%S')" >> $LOG_FILE
  sudo docker-compose -p ${DOCKER_APP_NAME} -f docker-compose.yml up -d --build app-green

  sleep 30

  echo "blue 중단 시작 : $(date '+%Y-%m-%d %H:%M:%S')" >> $LOG_FILE
  sudo docker stop couponmoa-blue
  sudo docker rm couponmoa-blue
  sudo docker image prune -af

  echo "blue 중단 완료 : $(date '+%Y-%m-%d %H:%M:%S')" >> $LOG_FILE
fi

echo "배포 종료  : $(date '+%Y-%m-%d %H:%M:%S')" >> $LOG_FILE
echo "===================== 배포 완료 =====================" >> $LOG_FILE
echo "" >> $LOG_FILE
