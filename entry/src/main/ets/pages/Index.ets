import { abilityAccessCtrl, common, PermissionRequestResult, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import GuitarTuner from '../viewmodel/guitarTuner';

interface StringInfo {
  number: number;
  name: string;
  frequency: number;
  color: string;
}

@Entry
@Component
struct Index {
  @State tuner: GuitarTuner = new GuitarTuner();
  @State selectedString: number = 6;
  private strings: StringInfo[] = [
    {
      number: 6,
      name: 'E2',
      frequency: 82.41,
      color: '#FF6B6B'
    },
    {
      number: 5,
      name: 'A2',
      frequency: 110.00,
      color: '#4ECDC4'
    },
    {
      number: 4,
      name: 'D3',
      frequency: 146.83,
      color: '#45B7D1'
    },
    {
      number: 3,
      name: 'G3',
      frequency: 196.00,
      color: '#96CEB4'
    },
    {
      number: 2,
      name: 'B3',
      frequency: 246.94,
      color: '#FFEAA7'
    },
    {
      number: 1,
      name: 'E4',
      frequency: 329.63,
      color: '#DDA0DD'
    }
  ];

  onDidBuild(): void {
    this.requestMicPermission().then(() => {
      this.tuner.start();
      this.tuner.setTargetFrequency(this.getSelectedString().frequency);
    });
  }

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 135,
          colors: [[0x0a0a0a, 0.0], [0x1a1a2e, 1.0]]
        });
      Column() {
        Stack() {
          Circle()
            .width(220)
            .height(220)
            .fill('transparent')
            .stroke('#2A2A3A')
            .strokeWidth(2)
            .strokeDashArray([5, 5]);

          Circle()
            .width(200)
            .height(200)
            .fill('transparent')
            .stroke('#2A2A3A')
            .strokeWidth(10);

          Circle()
            .width(200)
            .height(200)
            .fill('transparent')
            .stroke(this.getTuningColor())
            .strokeWidth(10)
            .strokeDashArray([this.getCircleProgress(), 360])
            .rotate({ angle: -90 });

          Column() {
            Text(this.getSelectedString().name)
              .fontSize(48)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.getSelectedString().color)
              .fontFamily('monospace');

            Text(`${this.tuner.frequency.toFixed(0)}`)
              .fontSize(32)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .fontFamily('monospace')
              .margin({ top: 8 });

            Text('Hz')
              .fontSize(12)
              .fontColor('#666666')
              .margin({ top: -4 });

            Divider()
              .width(50)
              .height(1)
              .color('#333333')
              .margin({ top: 12, bottom: 8 });

            if (this.tuner.isInTune) {
              Column() {
                Text('✓')
                  .fontSize(20)
                  .fontColor('#4CAF50');
                Text('IN TUNE')
                  .fontSize(11)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#4CAF50')
                  .margin({ top: 2 });
              };
            } else if (this.tuner.suggestedTuning) {
              Column() {
                Text(this.tuner.centOffset > 0 ? '▼' : '▲')
                  .fontSize(18)
                  .fontColor(this.getTuningColor());
                Text(this.tuner.suggestedTuning)
                  .fontSize(10)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.getTuningColor())
                  .margin({ top: 2 });
              };
            } else {
              Column() {
                Image($r('app.media.play_fill'))
                  .width(18)
                  .height(18)
                  .fillColor('#888888');
                Text('PLAY')
                  .fontSize(10)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#888888')
                  .letterSpacing(1)
                  .margin({ top: 4 });
                Text('STRING')
                  .fontSize(9)
                  .fontColor('#666666');
              };
            }
          }
          .alignItems(HorizontalAlign.Center);
        }
        .width(240)
        .height(240);

        Text(`${this.tuner.centOffset > 0 ? '+' : ''}${this.tuner.centOffset.toFixed(0)} cent`)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getTuningColor())
          .fontFamily('monospace')
          .margin({ top: 5, bottom: 5 });

        Text(`target: ${this.getSelectedString().frequency} Hz`)
          .fontSize(11)
          .fontColor('#666666')
          .margin({ top: 5 });

        Blank()
          .height('12%');
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center);

      this.StringButton(this.strings[0], '25%', '25%');
      this.StringButton(this.strings[1], '15%', '50%');
      this.StringButton(this.strings[2], '25%', '75%');
      this.StringButton(this.strings[3], '75%', '75%');
      this.StringButton(this.strings[4], '85%', '50%');
      this.StringButton(this.strings[5], '75%', '25%');
    };
  }

  @Builder
  StringButton(string: StringInfo, x: string, y: string) {
    Column() {
      Text(string.name)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.selectedString === string.number ?
        string.color : '#AAAAAA');

      Text(string.number.toString())
        .fontSize(10)
        .fontColor('#666666')
        .margin({ top: 2 });
    }
    .width(52)
    .height(52)
    .backgroundColor(this.selectedString === string.number ?
      `${string.color}30` : '#1F1F2F')
    .borderRadius(26)
    .justifyContent(FlexAlign.Center)
    .border({
      width: this.selectedString === string.number ? 2 : 0,
      color: string.color,
      radius: 26
    })
    .onClick(() => {
      this.selectedString = string.number;
      this.tuner.setTargetFrequency(string.frequency);
    })
    .position({ x: x, y: y })
    .translate({ x: -26, y: -26 });
  }

  getCircleProgress(): number {
    const cent = Math.max(-50, Math.min(50, this.tuner.centOffset));
    const progress = ((cent + 50) / 100) * 360;
    return Math.max(0, Math.min(360, progress));
  }

  getSelectedString(): StringInfo {
    const found = this.strings.find(s => s.number === this.selectedString);
    return found || this.strings[0];
  }

  getTuningColor(): string {
    if (this.tuner.isInTune) {
      return '#4CAF50';
    }
    if (Math.abs(this.tuner.centOffset) < 5) {
      return '#FFC107';
    }
    return '#FF6B6B';
  }

  async requestMicPermission() {
    const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    const context = this.getUIContext().getHostContext();
    const permissions: Permissions[] = ['ohos.permission.MICROPHONE'];

    try {
      let granted =
        (await (atManager.requestPermissionsFromUser(context,
          permissions) as Promise<PermissionRequestResult>)).authResults[0] === 0;
      if (!granted) {
        granted = (await atManager.requestPermissionOnSetting(context, permissions))[0] ===
        abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
        if (!granted) {
          await (this.getUIContext().getHostContext() as common.UIAbilityContext).terminateSelf();
        }
      }
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`Failed to check access token. Code is ${err.code}, message is ${err.message}`);
    }
  }
}