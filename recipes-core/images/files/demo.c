// SPDX-License-Identifier: GPL-2.0+
/*
 * Copyright 2025 NXP
 */

#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <termios.h>
#include <unistd.h>
#include <string.h>

int main() {
    // Open the UART device file
    FILE *uart = fopen("/dev/ttyLP2", "r+");
    int uart_fd;

    if (uart == NULL) {
        perror("Failed to open UART\n");
        return EXIT_FAILURE;
    }

    uart_fd = fileno(uart);

    struct termios tty;
    if (tcgetattr(uart_fd, &tty) != 0) {
        printf("Serial: error from tcgetattr\n");
        return 0;
    }

    cfsetospeed(&tty, B115200);
    cfsetispeed(&tty, B115200);

    tty.c_cflag = (tty.c_cflag & ~CSIZE) | CS8; // 8-bit chars
    // disable IGNBRK for mismatched speed tests; otherwise receive break
    // as \000 chars
    tty.c_iflag &= ~(IGNBRK | BRKINT | PARMRK | ISTRIP | INLCR | IGNCR | IXON | IXOFF | IXANY);
    tty.c_iflag |= ICRNL;
    tty.c_lflag = 0;
    tty.c_lflag |= ICANON;     // no signaling chars, no echo,
                         // no canonical processing
    tty.c_oflag = 0;     // no remapping, no delays
    tty.c_cc[VMIN] = 0;  // read blocks
    tty.c_cc[VTIME] = 0.5; // 0.5 seconds read timeout

    tty.c_cflag |= (CLOCAL | CREAD);   // ignore modem controls,
                                       // enable reading
    tty.c_cflag &= ~(PARENB | PARODD); // shut off parity
    tty.c_cflag &= ~CSTOPB;
    tty.c_cflag &= ~CRTSCTS;

    if (tcsetattr(uart_fd, TCSANOW, &tty) != 0) {
        printf("Serial: error from tcsetattr\n");
        return 0;
    }
    printf ("Success setting tcsetattr\n");


    while(1){
    // Write to UART
    const char *message = "e\r";
        if (fwrite(message, sizeof(char), strlen(message), uart) < strlen(message)) {
            perror("Failed to write to UART\n");
            fclose(uart);
            return EXIT_FAILURE;
        }
        fflush(uart);
        printf("Wrote something\n");
        // Read from UART
        // usleep(1000);

        char buffer[100];
        if (fgets(buffer, sizeof(buffer), uart) != NULL) {
            printf("Received: %s\n", buffer);
        }
        else {
            perror("Failed to read from UART\n");
        }

    // Write to UART
    const char *message1 = "c\r";
        if (fwrite(message1, sizeof(char), strlen(message), uart) < strlen(message)) {
            perror("Failed to write to UART\n");
            fclose(uart);
            return EXIT_FAILURE;
        }
        fflush(uart);
        printf("Wrote something\n");
        // Read from UART
        // usleep(1000);

        char buffer1[100];
        if (fgets(buffer1, sizeof(buffer1), uart) != NULL) {
            printf("Received: %s\n", buffer1);
        }
        else {
            perror("Failed to read from UART\n");
        }

    }

    // Close the UART device file
    fclose(uart);
    return EXIT_SUCCESS;
}
