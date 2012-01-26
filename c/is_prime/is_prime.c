/*
 *
 * is_prime.c
 * 
 * License: Public Domain - http://creativecommons.org/licenses/publicdomain/
 *
 */

#include <stdio.h>

int is_prime(long int x) {
  long int i;

  if (x <  2) return 0;
  if (x <= 3) return 1;

  for (i = 2; i < x; i++) {
    if (x % i == 0)
      return 0;
  }

  return 1;
}

int main() {
  long int i;

  for (i = 1;i <= 400000;i++) {
    if (is_prime(i))
      printf("%ld\n",i);
  }

  return 0;
}
