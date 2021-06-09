/*Copyright (C) 2008-2009  Timothy B. Terriberry (tterribe@xiph.org)
  You can redistribute this library and/or modify it under the terms of the
   GNU Lesser General Public License as published by the Free Software
   Foundation; either version 2.1 of the License, or (at your option) any later
   version.*/
#if !defined(_qrcode_binarize_H)
# define _qrcode_binarize_H (1)

typedef enum qr_binarize_invert_flag {
  QR_BINARIZE_NO_INVERT,
  QR_BINARIZE_INVERT,
} qr_binarize_invert_flag;

/*Binarizes a grayscale image.*/
void qr_binarize(unsigned char *_img, int _width, int _height, qr_binarize_invert_flag invert);

#endif
