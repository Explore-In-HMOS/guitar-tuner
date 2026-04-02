import audio from '@ohos.multimedia.audio';
import { fft } from '../libs/fastFourierTransform';

interface AudioBuffer {
  buffer: ArrayBuffer;
  size: number;
}

@Observed
export default class GuitarTuner {
  private audioCapturer: audio.AudioCapturer | undefined = undefined;
  private sampleRate: number = 16000;
  private bufferSize: number = 4096;
  private pcmBuffer: number[] = [];

  frequency: number = 0;
  noteName: string = '';
  centOffset: number = 0;
  isInTune: boolean = false;
  suggestedTuning: string = '';

  private targetFrequency: number = 82.41;
  private isCapturing: boolean = false;

  async start() {
    await this.stop();

    try {
      this.isCapturing = true;

      let audioStreamInfo: audio.AudioStreamInfo = {
        samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_16000,
        channels: audio.AudioChannel.CHANNEL_1,
        sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
        encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
      };

      let audioCapturerInfo: audio.AudioCapturerInfo = {
        source: audio.SourceType.SOURCE_TYPE_MIC,
        capturerFlags: 0
      };

      let audioCapturerOptions: audio.AudioCapturerOptions = {
        streamInfo: audioStreamInfo,
        capturerInfo: audioCapturerInfo
      };

      this.audioCapturer = await audio.createAudioCapturer(audioCapturerOptions);

      if (this.audioCapturer !== undefined) {
        this.audioCapturer.on('audioInterrupt', (interruptEvent: audio.InterruptEvent) => {
          if (interruptEvent.forceType === audio.InterruptForceType.INTERRUPT_FORCE) {
            console.info('Audio interruption: Recording is stopping...');
          } else {
            console.info('Audio interruption: Shared or temporary condition.');
          }
        });
      }

      this.audioCapturer.on('readData', (buffer: ArrayBuffer) => {
        if (!this.isCapturing) {
          return;
        }
        this.processPCMData(buffer);
      });

      await this.audioCapturer.start();

    } catch (e) {
      console.error('GuitarTuner start error:', e);
      this.isCapturing = false;
    }
  }

  setTargetFrequency(freq: number) {
    this.targetFrequency = freq;
  }

  private processPCMData(buffer: ArrayBuffer) {
    const samples = new Int16Array(buffer);
    for (let i = 0; i < samples.length; i++) {
      this.pcmBuffer.push(samples[i] / 32768.0);
    }

    while (this.pcmBuffer.length >= this.bufferSize) {
      const frame = this.pcmBuffer.splice(0, this.bufferSize);
      this.analyzeFrame(frame);
    }
  }

  private analyzeFrame(samples: number[]) {
    const mean = samples.reduce((a, b) => a + b, 0) / samples.length;
    let normalized = samples.map(v => v - mean);
    normalized = this.applyHanning(normalized);

    const spectrum = fft(normalized);

    const magnitudes = spectrum.slice(0, spectrum.length / 2).map(c =>
    Math.sqrt(c.re * c.re + c.im * c.im)
    );

    let maxMag = 0;
    let peakIdx = 0;
    for (let i = 0; i < magnitudes.length; i++) {
      if (magnitudes[i] > maxMag) {
        maxMag = magnitudes[i];
        peakIdx = i;
      }
    }

    if (maxMag < 0.02) {
      this.frequency = 0;
      return;
    }

    const preciseIdx = this.parabolicInterpPeak(magnitudes, peakIdx);
    const frequency = preciseIdx * this.sampleRate / this.bufferSize;

    this.frequency = frequency;
    this.calculateTuning(frequency);
  }

  private calculateTuning(freq: number) {
    if (freq === 0) {
      this.centOffset = 0;
      this.isInTune = false;
      this.suggestedTuning = '';
      return;
    }

    const cent = 1200 * Math.log2(freq / this.targetFrequency);
    this.centOffset = cent;
    this.isInTune = Math.abs(cent) <= 5;

    if (Math.abs(cent) > 5) {
      if (cent > 0) {
        this.suggestedTuning = 'Loosen';
      } else {
        this.suggestedTuning = 'Tighten';
      }
    } else {
      this.suggestedTuning = '';
    }
  }

  async stop() {
    this.isCapturing = false;

    if (this.audioCapturer) {
      try {
        this.audioCapturer.off('readData');
      } catch(e) { }
      try {
        await this.audioCapturer.stop();
      } catch(e) { }
      try {
        await this.audioCapturer.release();
      } catch(e) { }
      this.audioCapturer = undefined;
    }

    this.pcmBuffer = [];
    this.frequency = 0;
    this.centOffset = 0;
    this.isInTune = false;
    this.suggestedTuning = '';
  }

  private parabolicInterpPeak(mags: number[], index: number): number {
    if (index <= 0 || index >= mags.length - 1) {
      return index;
    }
    const alpha = mags[index - 1];
    const beta = mags[index];
    const gamma = mags[index + 1];
    const p = 0.5 * (alpha - gamma) / (alpha - 2 * beta + gamma);
    return index + p;
  }

  private applyHanning(samples: number[]): number[] {
    const N = samples.length;
    return samples.map((x, n) => x * (0.5 - 0.5 * Math.cos(2 * Math.PI * n / (N - 1))));
  }
}