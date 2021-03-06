#ifndef __TIME_H__
#define __TIME_H__

#include <stdint.h>
#include <stddef.h>

extern volatile uint64_t uptime_raw;
extern volatile uint64_t uptime_sec;

void ksleep(uint64_t);

#endif
