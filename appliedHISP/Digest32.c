//
//  Digest32.h
//  appliedHISP
//
//  Created by Robert Larkin on 8/9/14.
//  Copyright (c) 2014 Oxford Computing Lab. All rights reserved.
//
//  Code modified from the work of
//  Long Hoang Nguyen and Andrew William Roscoe
//
//  That appeared in the 19th Proceedings of the
//  International Workshop on Fast Software Encryption
//  or FSE 2012, in 19-21 March 2012, Washington DC, USA.
//

#include <string.h>
#include <stdlib.h>
#include <stddef.h>
#include <stdio.h>
#include <time.h>
#include "Digest32.h"
#include "rijndael-alg-fst.h"

typedef unsigned char      UINT8;  /* 1 byte   */
//typedef unsigned short     UINT16; /* 2 byte   */ // unused in this implementation
typedef unsigned int       UINT32; /* 4 byte   */
typedef unsigned long long UINT64; /* 8 bytes  */
typedef unsigned long      UWORD;  /* Register */

#define DIGEST_KEY_LEN           16  /* DIGEST takes 16 bytes of external key */
#define MUL64(a,b) ((UINT64)((UINT64)(UINT32)(a) * (UINT64)(UINT32)(b)))
#define MUL32(d,k1,k2) ((UINT32) (((UINT32) MUL64(d,k1)) + ((UINT32) (MUL64(d,k2) >> 32))))
#define ADD32(a,b) ((UINT32) (((UINT32) a) + ((UINT32) ((UINT64) b >> 32))))

#define LOAD_UINT32_LITTLE(ptr)     (*(UINT32 *)(ptr))



#define DIGEST_OUTPUT_LEN       4       /* Only 4 is allowed in this implementation  */
#define STREAMS (DIGEST_OUTPUT_LEN / 4) /* Number of times hash is applied  */
#define L1_KEY_LEN         1024         /* Internal key bytes                 */
#define L1_KEY_SHIFT         4          /* BYTES, Toeplitz key shift between streams */


/* DIGEST uses AES with 16 byte block and key lengths */
#define AES_BLOCK_LEN  16
#define AES_ROUNDS	   ((DIGEST_KEY_LEN / 4) + 6)
typedef UINT8          aes_int_key[AES_ROUNDS+1][4][4]; /* AES internal */
#define aes_encryption(in,out,int_key) \
rijndaelEncrypt((u32 *)(int_key), AES_ROUNDS, (u8 *)(in), (u8 *)(out))
#define aes_key_setup(key,int_key) \
rijndaelKeySetupEnc((u32 *)(int_key), (const unsigned char *)(key), \
DIGEST_KEY_LEN*8)

void kdf(void *buffer_ptr, aes_int_key key, UINT8 index, int nbytes)
{
    UINT8 in_buf[AES_BLOCK_LEN] = {0};
    UINT8 out_buf[AES_BLOCK_LEN];
    UINT8 *dst_buf = (UINT8 *)buffer_ptr;
    int i;
    
    /* Setup the initial value */
    in_buf[AES_BLOCK_LEN-9] = index;
    in_buf[AES_BLOCK_LEN-1] = i = 1;
    
    while (nbytes >= AES_BLOCK_LEN) {
        aes_encryption(in_buf, out_buf, key);
        memcpy(dst_buf,out_buf,AES_BLOCK_LEN);
        in_buf[AES_BLOCK_LEN-1] = ++i;
        nbytes -= AES_BLOCK_LEN;
        dst_buf += AES_BLOCK_LEN;
    }
    if (nbytes) {
        aes_encryption(in_buf, out_buf, key);
        memcpy(dst_buf,out_buf,nbytes);
    }
}

#if (DIGEST_OUTPUT_LEN == 4) // ONE 32-BIT WORDS OR 32 BITS

static void digest_aux(void *kp, void *dp, void *hp, UINT32 dlen)
//void digest_aux(void *kp, void *dp, void *hp, UINT32 dlen)
{
    UINT32 h;
    UWORD c = dlen / 32;
    UINT32 *k = (UINT32 *)kp;
    UINT32 *d = (UINT32 *)dp;
    UINT32 d0,d1,d2,d3,d4,d5,d6,d7;
    UINT32 k0,k1,k2,k3,k4,k5,k6,k7,k8;
    
    h = *((UINT32 *)hp);
    k0 = *(k+0);
    do {
        d0 = LOAD_UINT32_LITTLE(d+0); d1 = LOAD_UINT32_LITTLE(d+1);
        d2 = LOAD_UINT32_LITTLE(d+2); d3 = LOAD_UINT32_LITTLE(d+3);
        d4 = LOAD_UINT32_LITTLE(d+4); d5 = LOAD_UINT32_LITTLE(d+5);
        d6 = LOAD_UINT32_LITTLE(d+6); d7 = LOAD_UINT32_LITTLE(d+7);
        
        k1 = *(k+1); k2 = *(k+2); k3 = *(k+3); k4 = *(k+4);
        k5 = *(k+5); k6 = *(k+6); k7 = *(k+7); k8 = *(k+8);
        
        h+= MUL32(d0,k0,k1);
        h+= MUL32(d1,k1,k2);
        h+= MUL32(d2,k2,k3);
        h+= MUL32(d3,k3,k4);
        h+= MUL32(d4,k4,k5);
        h+= MUL32(d5,k5,k6);
        h+= MUL32(d6,k6,k7);
        h+= MUL32(d7,k7,k8);
        
        k0 = k8;
        
        d += 8;
        k += 8;
    } while (--c);
    *((UINT32 *)hp) = h;
}

unsigned int digestInputWithKey(const char *input, int input_len, const char* key)
{
    aes_int_key prf_key;
    UINT8  digest_key [L1_KEY_LEN + L1_KEY_SHIFT * STREAMS];
    char *data_ptr;
    int data_len, i;
    UINT8 digest_result[STREAMS*sizeof(UINT32)];
    unsigned int result;
    
    memset(digest_result, 0, sizeof(digest_result)); // must zero out array for objective-c
    
    data_len = input_len + (L1_KEY_LEN - input_len % L1_KEY_LEN);
    data_ptr = (char *)malloc(data_len + 16);
    
    for (i = 0; i < data_len; i++) {
        data_ptr[i] = input[i];
    }
    
    if (input_len%L1_KEY_LEN != 0) { // pad data with '0'
        for (i=0; i<(L1_KEY_LEN - input_len % L1_KEY_LEN); i++) {
            data_ptr[input_len+i] = '0';
        }
    }
    
    aes_key_setup(key,prf_key);
    kdf(digest_key, prf_key, 1, sizeof(digest_key));
    // use above to create 1040 byte array to process data input
    // each time process the 1024 + 16 byte block
    
    //===================================================
    
    while (data_len >= L1_KEY_LEN) {
        digest_aux(digest_key, data_ptr, digest_result, L1_KEY_LEN);
        data_len -= L1_KEY_LEN;
        data_ptr += L1_KEY_LEN;
    }
    
    result = *(unsigned int *)&digest_result[0];
        
    return result;
}


#endif





