FROM debian:latest

RUN apt update && apt install nasm binutils make xorriso grub2 -y

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

WORKDIR /volumes

CMD [ "/entrypoint.sh" ]
