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

  // 1. Obiekt odpowiadający za kontrolę przewijania
  scroller: Scroller = new Scroller();

  // 2. Prędkość przewijania (0 = zatrzymane)
  @State scrollSpeed: number = 0;
  private intervalId: number = -1;
  private hideTimeoutId: number = -1;
  @State isSpeedVisible: boolean = false;
  aboutToAppear() {
    let params = router.getParams() as Record<string, string>;
    if (params) {
      this.title = params['title'];
      this.content = params['content'];
    }

    // 3. Silnik przewijania: pętla wykonująca się co 50 milisekund
    this.intervalId = setInterval(() => {
      if (this.scrollSpeed !== 0) {
        // scrollBy(x, y) - Przewija widok o naszą prędkość (w pikselach) w osi Y
        this.scroller.scrollBy(0, this.scrollSpeed);
      }
    }, 50);
  }
  updateSpeed(newSpeed: number) {
    this.scrollSpeed = newSpeed;

    // 1. Pokazujemy wskaźnik płynnie (jeśli kręcimy)
    if (newSpeed !== 0) {
      animateTo({ duration: 200 }, () => {
        this.isSpeedVisible = true;
      });
    }

    // 2. Jeśli licznik już tykał (bo kręciłeś sekundę temu), kasujemy go
    if (this.hideTimeoutId !== -1) {
      clearTimeout(this.hideTimeoutId);
    }

    // 3. Odpalamy nowy licznik. Po 2 sekundach bezczynności chowa wskaźnik.
    this.hideTimeoutId = setTimeout(() => {
      animateTo({ duration: 500 }, () => {
        this.isSpeedVisible = false;
      });
    }, 2000);
  }
  aboutToDisappear() {
    // KRYTYCZNE: Zatrzymujemy pętlę po wyjściu z piosenki!
    // Inaczej pętla kręciłaby się w tle, błyskawicznie drenując baterię zegarka.
    if (this.intervalId !== -1) {
      clearInterval(this.intervalId);
    }
  }

  parseLineToBlocks(line: string): ChordBlock[] {
    let blocks: ChordBlock[] = [];
    let parts = line.split(/(\[[^\]]+\])/);
    let currentChord = '';

    for (let i = 0; i < parts.length; i++) {
      let part = parts[i];
      if (part.startsWith('[') && part.endsWith(']')) {
        currentChord = part.substring(1, part.length - 1);
      } else {
        let cleanLyric = part.trim();
        if (cleanLyric.length > 0 || currentChord !== '') {
          blocks.push({ chord: currentChord, lyric: cleanLyric });
          currentChord = '';
        }
      }
    }
    return blocks;
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {

      // 1. Zwykły Scroll z tekstem piosenki
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
              ForEach(this.parseLineToBlocks(line), (block: ChordBlock) => {
                Column() {
                  Text(block.chord !== '' ? block.chord : ' ')
                    .fontSize(8)
                    .fontColor('#ff4444')
                    .fontWeight(FontWeight.Bold)
                    .margin({ bottom: 2 })

                  Text(block.lyric !== '' ? block.lyric : ' ')
                    .fontSize(10)
                    .fontColor(Color.White)
                }
                .alignItems(HorizontalAlign.Start)
                .margin({ right: 8, bottom: 8 })
              })
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

      // 2. NOWOŚĆ: Suwak "Pedał gazu" sprzęgnięty z fizyczną koronką!
      Row() {
        Blank() // Spycha nasz suwak do prawej krawędzi ekranu

        Slider({
          value: this.scrollSpeed,
          min: 0,       // Maksymalna prędkość w górę
          max: 3,        // Maksymalna prędkość w dół
          step: 0.2,
          style: SliderStyle.OutSet,
          direction: Axis.Vertical // Suwak pionowy
        })
          .height('60%')
          .width(30)
          .margin({ right: 5 })
          .focusable(true)          // WAŻNE: Pozwala przypiąć koronkę
          .defaultFocus(true)       // WAŻNE: Wymusza na koronce sterowanie tym elementem
          .onChange((value: number) => {
            this.scrollSpeed = value; // Aktualizuje prędkość przewijania
            this.updateSpeed(value); // Używamy naszej nowej funkcji!

          })
      }
      .width('100%')
      .height('100%')
      // Ustawienie "Transparent" sprawia, że warstwa z suwakiem nie blokuje
      // dotykania ekranu (możesz np. kliknąć przez nią, aby zatrzymać tekst)
      .hitTestBehavior(HitTestMode.Transparent)

      // 3. Dynamiczny wskaźnik prędkości
      if (this.isSpeedVisible && this.scrollSpeed !== 0) {
        Text(`Prędkość: ${this.scrollSpeed > 0 ? '+' : ''}${this.scrollSpeed.toFixed(1)}`)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.Black)
          .backgroundColor(Color.White)
          .padding({ top: 4, bottom: 4, left: 10, right: 10 })
          .borderRadius(12)
          .margin({ bottom: 20 })
          // To jest magia ArkTS - definiujemy efekt pojawiania się i znikania
          .transition({
            type: TransitionType.All,
            opacity: 0,                   // Zmienia przezroczystość do zera
            scale: { x: 0.8, y: 0.8 }     // Dodatkowo lekko go pomniejsza przy znikaniu
          })
      }

    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
    // 4. Tapnięcie palcem w ekran działa jako hamulec
    .onClick(() => {
      this.scrollSpeed = 0;
    })
  }
}