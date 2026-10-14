#include <zephyr/kernel.h>
#include <zephyr/logging/log.h>
#include <zephyr/drivers/pcie/pcie.h>

LOG_MODULE_REGISTER(pcie_audio_app, LOG_LEVEL_INF);

#define AUDIO_SAMPLE_RATE_HZ   48000
#define AUDIO_FRAME_SAMPLES    1024
#define AUDIO_FRAME_SIZE_BYTES (AUDIO_FRAME_SAMPLES * sizeof(int16_t))
#define FRAME_DEADLINE_US      21330 /* 21.33 ms */

int main(void)
{
    LOG_INF("==================================================");
    LOG_INF("  Real-Time PCIe Audio Streaming POC");
    LOG_INF("  Target: qemu_cortex_a53 | OS: Zephyr RTOS");
    LOG_INF("==================================================");
    LOG_INF("Spec: 48 kHz, 16-bit PCM, 1024 samples/frame (%zu bytes)",
            AUDIO_FRAME_SIZE_BYTES);
    LOG_INF("Processing Deadline: %u us (%u.%02u ms)",
            FRAME_DEADLINE_US, FRAME_DEADLINE_US / 1000, (FRAME_DEADLINE_US % 1000) / 10);
    LOG_INF("--------------------------------------------------");
    LOG_INF("System Initialized.");

    return 0;
}
