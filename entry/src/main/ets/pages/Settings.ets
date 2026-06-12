import router from '@ohos.router';
import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';

@Entry
@Component
struct Settings {
  @State message: string = '';
  // MAGIA: Globalna zmienna. Domyślnie true (ciemny motyw)
  @StorageLink('isDarkTheme') isDarkTheme: boolean = true;

  clearAllSongs() {
    let context = getContext(this) as common.UIAbilityContext;
    let filesDir = context.filesDir;

    try {
      let filenames = fs.listFileSync(filesDir);
      let deleteCount = 0;
      for (let name of filenames) {
        if (name.endsWith('.txt')) {
          fs.unlinkSync(filesDir + '/' + name);
          deleteCount++;
        }
      }
      this.message = `Pomyślnie usunięto piosenki (${deleteCount}).`;
    } catch (error) {
      this.message = `Błąd podczas usuwania: ${error}`;
    }
  }

  build() {
    Column() {
      Text('Ustawienia')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        // Dynamiczny kolor tekstu
        .fontColor(this.isDarkTheme ? Color.White : Color.Black)
        .margin({ top: 30, bottom: 20 })

      // PRZEŁĄCZNIK MOTYWU
      Row() {
        Text('Ciemny motyw')
          .fontSize(16)
          .fontColor(this.isDarkTheme ? Color.White : Color.Black)
          .margin({ right: 10 })

        Toggle({ type: ToggleType.Switch, isOn: this.isDarkTheme })
          .selectedColor('#45a2f8')
          .onChange((isOn: boolean) => {
            this.isDarkTheme = isOn; // To natychmiast zmieni kolory w całej apce!
          })
      }.margin({ bottom: 20 })

      Button('Wyczyść wszystkie piosenki')
        .width('80%')
        .backgroundColor('#b3261e')
        .onClick(() => { this.clearAllSongs(); })

      if (this.message !== '') {
        Text(this.message)
          .fontSize(14)
          .fontColor(this.message.includes('Błąd') ? Color.Red : Color.Green)
          .textAlign(TextAlign.Center)
          .margin({ top: 15 })
          .padding(10)
      }

      Button('Wróć')
        .width('50%')
        .margin({ top: 20 })
        .backgroundColor(this.isDarkTheme ? '#444444' : '#cccccc')
        .fontColor(this.isDarkTheme ? Color.White : Color.Black)
        .onClick(() => { router.back(); })
    }
    .width('100%')
    .height('100%')
    // Dynamiczny kolor tła
    .backgroundColor(this.isDarkTheme ? Color.Black : Color.White)
  }
}