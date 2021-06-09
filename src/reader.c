/*Copyright (C) 2008-2009  Timothy B. Terriberry (tterribe@xiph.org)
  You can redistribute this library and/or modify it under the terms of the
   GNU Lesser General Public License as published by the Free Software
   Foundation; either version 2.1 of the License, or (at your option) any later
   version.*/
#include "binarize.h"
#include "image.h"
#include "qrcode.h"
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

static int qr_code_data_cmp(const void *_a, const void *_b) {
    const qr_code_data *a = _a;
    const qr_code_data *b = _b;
    int ai = 0;
    int bi = 0;

    /*Find the top-left corner of each bounding box.*/
    for (int i = 1; i < 4; i++) {
        if (
            a->bbox[i][1] < a->bbox[ai][1]
         || (a->bbox[i][1] == a->bbox[ai][1] && a->bbox[i][0] < a->bbox[ai][0])
        ) {
            ai = i;
        }

        if (
            b->bbox[i][1] < b->bbox[bi][1]
         || (b->bbox[i][1] == b->bbox[bi][1] && b->bbox[i][0] < b->bbox[bi][0])
        ) {
            bi = i;
        }
    }
    /*Sort the codes in top-down, left-right order.*/
    return (
        (((a->bbox[ai][1] > b->bbox[bi][1]) - (a->bbox[ai][1] < b->bbox[bi][1])) << 1)
      + (a->bbox[ai][0] > b->bbox[bi][0])
      - (a->bbox[ai][0] < b->bbox[bi][0])
    );
}

int main(int _argc, char **_argv) {
    qr_reader *reader;
    qr_code_data_list qrlist;
    char **text;
    int i;
    unsigned char *img;
    int width;
    int height;
    if (_argc < 2) {
        fprintf(stderr, "usage: %s <image>.png\n", _argv[0]);
        return EXIT_FAILURE;
    }

    {
        FILE *fin = fopen(_argv[1], "rb");
        if (fin == NULL) {
            fprintf(stderr, "'%s' not found.\n", _argv[1]);
            return EXIT_FAILURE;
        }
        image_read_png(&img, &width, &height, fin);
        fclose(fin);
    }

    qr_binarize(img, width, height, QR_BINARIZE_INVERT);

    {
        FILE *fout = fopen("binary.png", "wb");
        image_write_png(img, width, height, fout);
        fclose(fout);
    }

    reader = qr_reader_alloc();
    qr_code_data_list_init(&qrlist);
    if (qr_reader_locate(reader, &qrlist, img, width, height) > 0) {

        /*Sort the codes to make test results reproducible.*/
        qsort(
            qrlist.qrdata,
            qrlist.nqrdata,
            sizeof(*qrlist.qrdata),
            qr_code_data_cmp
        );
        int ntext = qr_code_data_list_extract_text(&qrlist, &text, 1);

        for (int qridx = 0; qridx < qrlist.nqrdata; qridx++) {
            struct qr_code_data *const qr_code = qrlist.qrdata + qridx;
            printf("QR Code %d:\n", qridx);
            printf("  Version: %d\n", qr_code->version);
            printf("  ECC level: %c\n", "LMQH"[qr_code->ecc_level]);
            printf("  Mask: %d\n", qr_code->mask);
            printf(
                "  Bounds: (%d, %d) (%d, %d) (%d, %d) (%d, %d)\n",
                qr_code->bbox[0][0], qr_code->bbox[0][1],
                qr_code->bbox[1][0], qr_code->bbox[1][1],
                qr_code->bbox[3][0], qr_code->bbox[3][1],
                qr_code->bbox[2][0], qr_code->bbox[2][1]
            );
            printf("  Center: (%d, %d)\n", qr_code->center[0], qr_code->center[1]);

            for (int jdx = 0; jdx < (qr_code->nentries); jdx++) {
                struct qr_code_data_entry *const entry = qr_code->entries + jdx;
                printf("  Data entry %d:\n", jdx);
                printf("    type: %d\n", entry->mode);
                if (QR_MODE_HAS_DATA(entry->mode)) {
                    printf("    length: %d\n", entry->payload.data.len);
                    printf("    data: ");
                    int bufdx = 0;
                    for (; bufdx < (entry->payload.data.len - 1); bufdx++) {
                        printf("%02X ", entry->payload.data.buf[bufdx]);
                    }
                    printf("%02X\n", entry->payload.data.buf[bufdx]);
                }
            }
        }

        for (i = 0; i < ntext; i++) {
            printf("Text: %s\n", text[i]);
        }
        qr_text_list_free(text, ntext);
        qr_code_data_list_clear(&qrlist);
    }
    qr_reader_free(reader);
    free(img);
    return EXIT_SUCCESS;
}
