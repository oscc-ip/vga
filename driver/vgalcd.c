#include <am.h>
#include <klib.h>
#include <klib-macros.h>

#define VGALCD_BASE_ADDR    0x10004000
#define VGALCD_REG_CTRL     *((volatile uint32_t *)(VGALCD_BASE_ADDR + 0))
#define VGALCD_REG_HVVL     *((volatile uint32_t *)(VGALCD_BASE_ADDR + 4))
#define VGALCD_REG_HTIM     *((volatile uint32_t *)(VGALCD_BASE_ADDR + 8))
#define VGALCD_REG_VTIM     *((volatile uint32_t *)(VGALCD_BASE_ADDR + 12))
#define VGALCD_REG_FBBA1    *((volatile uint32_t *)(VGALCD_BASE_ADDR + 16))
#define VGALCD_REG_FBBA2    *((volatile uint32_t *)(VGALCD_BASE_ADDR + 20))
#define VGALCD_REG_THOLD    *((volatile uint32_t *)(VGALCD_BASE_ADDR + 24))
#define VGALCD_REG_STAT     *((volatile uint32_t *)(VGALCD_BASE_ADDR + 28))

#define VGALCD_FB1_ADDR     0x80110000
#define VGALCD_FB2_ADDR     0x80120000
#define VGALCD_FB_TEST_SIZE (4 * 1024)
#define VGALCD_FB_TEST_STEP 256

#define VGALCD_HVSIZE       640
#define VGALCD_VVSIZE       480

void vgalcd_init() {
    VGALCD_REG_CTRL = (uint32_t)0;
    VGALCD_REG_HVVL = (uint32_t)0x01DF027F;
    VGALCD_REG_HTIM = (uint32_t)0x02F17C0F;
    VGALCD_REG_VTIM = (uint32_t)0x02000409;
    VGALCD_REG_FBBA1 = VGALCD_FB1_ADDR;
    VGALCD_REG_FBBA2 = VGALCD_FB2_ADDR;
    printf("HVLEN: %d VVLEN: %d\n", (VGALCD_REG_HVVL & 0xFFFF) + 1, ((VGALCD_REG_HVVL >> 16) & 0xFFFF) + 1);
    printf("HFPSIZE: %d HSNSIZE: %d HBPSIZE: %d\n", (VGALCD_REG_HTIM & 0x3FF) + 1, ((VGALCD_REG_HTIM >> 10) & 0x3FF) + 1, ((VGALCD_REG_HTIM >> 20) & 0x3FF) + 1);
    printf("VFPSIZE: %d VSNSIZE: %d VBPSIZE: %d\n", (VGALCD_REG_VTIM & 0x3FF) + 1, ((VGALCD_REG_VTIM >> 10) & 0x3FF) + 1, ((VGALCD_REG_VTIM >> 20) & 0x3FF) + 1);
    printf("FB1: %x FB2: %x CTRL: %x\n", VGALCD_REG_FBBA1, VGALCD_REG_FBBA2, VGALCD_REG_CTRL);
}

void vgalcd_test_mode() {
    VGALCD_REG_CTRL = (uint32_t)0x110101; // div 2, test, en, rgb444
    printf("FB1: %x FB2: %x CTRL: %x\n", VGALCD_REG_FBBA1, VGALCD_REG_FBBA2, VGALCD_REG_CTRL);
}

void vgalcd_single_frame_mode(uint32_t addr) {
    VGALCD_REG_STAT = (uint32_t)0;
    VGALCD_REG_THOLD = (uint32_t)256;

    // R[11:8] G[7:4] B[3:0]
    uint16_t *mem_data = (void *)(uint64_t)addr;
    for(int i = 0; i < VGALCD_HVSIZE * VGALCD_VVSIZE; ++i) {
        if(i < VGALCD_HVSIZE * VGALCD_VVSIZE / 2) mem_data[i] = 0x0F;
        else mem_data[i] = 0xF0;
    }

    VGALCD_REG_CTRL = (uint32_t)0x1FA0101; // burlen 64, div 2, single frame, en, rgb444
    printf("FB1: %x FB2: %x CTRL: %x\n", VGALCD_REG_FBBA1, VGALCD_REG_FBBA2, VGALCD_REG_CTRL);
}

void vgalcd_two_frame_sw_mode(uint32_t addr1, uint32_t addr2) {
    VGALCD_REG_STAT = (uint32_t)0;
    VGALCD_REG_THOLD = (uint32_t)256;

    // R[11:8] G[7:4] B[3:0]
    uint16_t *mem_data1 = (void *)(uint64_t)addr1;
    uint16_t tmp_val;
    for(int i = 0; i < VGALCD_HVSIZE * VGALCD_VVSIZE; ++i) mem_data1[i] = 0x0F;
    for(int i = 0; i < VGALCD_HVSIZE * VGALCD_VVSIZE; ++i) {
        tmp_val = mem_data1[i];
        if(tmp_val != (uint16_t)0x0F) putstr("error\n");
    }

    uint16_t *mem_data2 = (void *)(uint64_t)addr2;
    for(int i = 0; i < VGALCD_HVSIZE * VGALCD_VVSIZE; ++i) mem_data2[i] = 0xF0;
    for(int i = 0; i < VGALCD_HVSIZE * VGALCD_VVSIZE; ++i) {
        tmp_val = mem_data2[i];
        if(tmp_val != (uint16_t)0xF0) putstr("error\n");
    }

    VGALCD_REG_CTRL = (uint32_t)0x1FA0111; // burlen 64, div 2, two frame sw, en, rgb444
    printf("FB1: %x FB2: %x CTRL: %x\n", VGALCD_REG_FBBA1, VGALCD_REG_FBBA2, VGALCD_REG_CTRL);
}

void vgalcd_fb_test(uint32_t addr) {
    uint64_t *mem_data = (void *)(uint64_t)addr;
    uint64_t len = VGALCD_FB_TEST_SIZE / sizeof(uint64_t);
    for (int i = 0; i < len; ++i) {
       if (i % VGALCD_FB_TEST_STEP == 0) {
            printf("[mem data][1] cnt: %d(%x), addr: %p\n", i, i, (mem_data + i));
        }
        mem_data[i] = i;
    }
    putstr("mem tests prepared\n");

    for(int i = 0; i < len; ++i) {
       if (i % VGALCD_FB_TEST_STEP == 0) {
            printf("[mem data][2] cnt: %d(%x), addr: %p\n", i, i, (mem_data + i));
        }
        if (mem_data[i] != i) {
            printf("[error] i: %lx mem_data[i]: %lx xor: %lx addr: %p\n", i, mem_data[i], i ^ mem_data[i], (mem_data + i));
        }
    }
}

int main()
{
    putstr("vgalcd test\n");
    putstr("vgalcd init\n");
    vgalcd_init();
    // vgalcd_test_mode();
    vgalcd_single_frame_mode(VGALCD_FB1_ADDR);
    // vgalcd_two_frame_sw_mode(VGALCD_FB1_ADDR, VGALCD_FB2_ADDR);
    // vgalcd_fb_test(VGALCD_FB1_ADDR);
    // vgalcd_fb_test(VGALCD_FB2_ADDR);


    // putstr("[write fb]\n");
    // uint64_t *fb = (void *)FB_ADDR;
    // for(int i = 0; i < VGA_H * VGA_W; ++i) {
    //     fb[i] = 0x123456;
    // }

    // mem_data = (void *)(VGA_FB_ADDR);
    // for(int i = 0; i < VGA_H * VGA_W; ++i){
    //     printf("[mem data] addr: %p val: %lx\n", mem_data + i, mem_data[i]);
    // }
    
    return 0;
}
