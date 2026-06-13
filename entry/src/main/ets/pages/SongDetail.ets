import router from '@ohos.router';

interface ChordBlock {
  chord: string;
  lyric: string;
}

@Entry
@Component
struct SongDetail {
  @State title: string = '';
  @State content: string = '';

  scroller: Scroller = new Scroller();
  @State scrollSpeed: number = 0;
  @State isSpeedVisible: boolean = false;
  private hideTimeoutId: number = -1;
  private intervalId: number = -1;

  @StorageLink('isDarkTheme') isDarkTheme: boolean = true;

  aboutToAppear() {
    let params = router.getParams() as Record<string, string>;
    if (params) {
      this.title = params['title'];
      this.content = params['content'];
    }

    this.intervalId = setInterval(() => {
      if (this.scrollSpeed !== 0) {
        this.scroller.scrollBy(0, this.scrollSpeed);
      }
    }, 50);
  }

  aboutToDisappear() {
    if (this.intervalId !== -1) {
      clearInterval(this.intervalId);
    }
    if (this.hideTimeoutId !== -1) {
      clearTimeout(this.hideTimeoutId);
    }
  }

  updateSpeed(newSpeed: number) {
    this.scrollSpeed = newSpeed;

    if (newSpeed !== 0) {
      animateTo({ duration: 200 }, () => {
        this.isSpeedVisible = true;
      });
    }

    if (this.hideTimeoutId !== -1) {
      clearTimeout(this.hideTimeoutId);
    }

    this.hideTimeoutId = setTimeout(() => {
      animateTo({ duration: 500 }, () => {
        this.isSpeedVisible = false;
      });
    }, 2000);
  }

  // NOWOŚĆ 1: Podział linijki na całe SŁOWA (rozdzielone spacjami)
  getWords(line: string): string[] {
    if (line.trim() === '') {
      return ['']; // Zwracamy pusty ciąg, by zachować pustą linijkę w układzie
    }
    return line.trim().split(/\s+/);
  }

  // NOWOŚĆ 2: Podział pojedynczego słowa na "klocki" z akordami
  parseWordToBlocks(word: string): ChordBlock[] {
    if (word === '') return [];

    let blocks: ChordBlock[] = [];
    let parts = word.split(/(\[[^\]]+\])/);
    let currentChord = '';

    for (let i = 0; i < parts.length; i++) {
      let part = parts[i];
      if (part.startsWith('[') && part.endsWith(']')) {
        currentChord = part.substring(1, part.length - 1);
      } else {
        if (part.length > 0 || currentChord !== '') {
          blocks.push({ chord: currentChord, lyric: part });
          currentChord = '';
        }
      }
    }
    return blocks;
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Scroll(this.scroller) {
        Column() {
          Text(this.title)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#45a2f8')
            .margin({ top: 30, bottom: 25 })
            .textAlign(TextAlign.Center)
            .width('100%')

          ForEach(this.content.split(/\r?\n/), (line: string) => {
            Flex({ wrap: FlexWrap.Wrap }) {

              if (line.trim() === '') {
                // Jeśli linijka w pliku jest pusta, wstawiamy przezroczysty znak,
                // żeby zachować odstęp między zwrotkami.
                Text(' ')
                  .fontSize(12)
                  .lineHeight(34)
              } else {

                // 1. Pętla przechodzi przez całe SŁOWA
                ForEach(this.getWords(line), (word: string) => {

                  // Row trzyma sylaby danego słowa "w ścisku"
                  Row() {
                    // 2. Pętla wstawia części słowa i akordy
                    ForEach(this.parseWordToBlocks(word), (block: ChordBlock) => {
                      Column() {
                        Text(block.chord !== '' ? block.chord : ' ')
                          .fontSize(8)
                          .fontColor('#ff4444')
                          .fontWeight(FontWeight.Bold)
                          .margin({ bottom: 2 })

                        Text(block.lyric !== '' ? block.lyric : ' ')
                          .fontSize(10)
                          .fontColor(this.isDarkTheme ? Color.White : Color.Black)
                      }
                      .alignItems(HorizontalAlign.Start)
                      // WAŻNE: Usunięto margin-right z wnętrza słowa!
                      // Dzięki temu d oraz ni są do siebie płynnie doklejone.
                    })
                  }
                  .margin({ right: 8, bottom: 8 }) // Odstęp 8px stosujemy dopiero między SŁOWAMI

                })
              }
            }
            .width('100%')
            .margin({ bottom: 5 })
          })
        }
        .width('100%')
        .padding({ left: 15, right: 15, bottom: 120 })
      }
      .width('100%')
      .height('100%')

      Row() {
        Blank()
        Slider({
          value: this.scrollSpeed,
          min: 0, max: 3, step: 0.2,
          style: SliderStyle.OutSet,
          direction: Axis.Vertical
        })
          .height('60%')
          .width(30)
          .margin({ right: 5 })
          .focusable(true)
          .defaultFocus(true)
          .onChange((value: number) => { this.updateSpeed(value); })
      }
      .width('100%')
      .height('100%')
      .hitTestBehavior(HitTestMode.Transparent)

      if (this.isSpeedVisible && this.scrollSpeed !== 0) {
        Text(`Prędkość: ${this.scrollSpeed > 0 ? '+' : ''}${this.scrollSpeed.toFixed(1)}`)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isDarkTheme ? Color.Black : Color.White)
          .backgroundColor(this.isDarkTheme ? '#f0f0f0' : '#e0e0e0')
          .padding({ top: 4, bottom: 4, left: 10, right: 10 })
          .borderRadius(12)
          .margin({ bottom: 20 })
          .opacity(0.8)
          .transition({ type: TransitionType.All, opacity: 0, scale: { x: 0.8, y: 0.8 } })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.isDarkTheme ? Color.Black : Color.White)
    .onClick(() => { this.updateSpeed(0); })
  }
}