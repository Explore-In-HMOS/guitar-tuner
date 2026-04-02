interface GeneratedTypeLiteralInterface_1 {
  re: number;
  im: number;
}

export function fft(input: number[]): GeneratedTypeLiteralInterface_1[] {
  const N = input.length;
  if (N <= 1) {
    return [{ re: input[0], im: 0 }];
  }

  const even = fft(input.filter((_, i) => i % 2 === 0));
  const odd = fft(input.filter((_, i) => i % 2 !== 0));

  const result: GeneratedTypeLiteralInterface_1[] = new Array(N);

  for (let k = 0; k < N / 2; k++) {
    const angle = -2 * Math.PI * k / N;
    const twiddle: GeneratedTypeLiteralInterface_1 = { re: Math.cos(angle), im: Math.sin(angle) };

    const oddPart: GeneratedTypeLiteralInterface_1 = {
      re: twiddle.re * odd[k].re - twiddle.im * odd[k].im,
      im: twiddle.re * odd[k].im + twiddle.im * odd[k].re
    };

    result[k] = { re: even[k].re + oddPart.re, im: even[k].im + oddPart.im };
    result[k + N / 2] = { re: even[k].re - oddPart.re, im: even[k].im - oddPart.im };
  }

  return result;
}
