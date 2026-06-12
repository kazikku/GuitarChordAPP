import router from '@ohos.router';

@Entry
@Component
struct Index {
  @State message: string = 'Obróć zegarek na nadgarstku';

  build() {

    RelativeContainer() {
      Text(this.message)
        .id('welcomeText')
        .fontSize(24)
        .textAlign(TextAlign.Center)
        .padding({left:10,right:10})
        .fontWeight(FontWeight.Bold)
        .alignRules({
          center: { anchor: '__container__', align: VerticalAlign.Center },
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })
        .onClick(() => {
          router.pushUrl({url:'pages/MainList'}).catch((err: Error)=>{console.error('Błąd nawigacji: ${err.message}');});
        })
    }
    .height('100%')
    .width('100%')
  }
}