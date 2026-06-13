import util from '@ohos.util';
import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import http from '@ohos.net.http';
import fs from '@ohos.file.fs';


interface Song {
  id: string;
  title: string;
  content: string;
}

@Entry
@Component
struct MainList {
  @State songsList: Song[] = [];
  @State isLoading: boolean = false;
  @State errorMessage: string = '';

  @StorageLink('isDarkTheme') isDarkTheme: boolean = true;

  onPageShow() {
    this.loadSongsFromWatchMemory();
  }

  // 1. FUNKCJA CZYTAJĄCA PLIKI Z PAMIĘCI ZEGARKA (Zamiast rawfile)
  loadSongsFromWatchMemory() {
    let context = getContext(this) as common.UIAbilityContext;
    let filesDir = context.filesDir; // Ścieżka do bezpiecznej pamięci aplikacji
    let loadedSongs: Song[] = [];

    try {
      // Pobiera nazwy wszystkich plików w pamięci
      let filenames = fs.listFileSync(filesDir);

      let counter = 0;
      for (let name of filenames) {
        if (!name.endsWith('.txt')) continue;

        let filePath = filesDir + '/' + name;

        // Magia modułu fs: od razu czyta jako czysty string! Żadnych bajtów!
        let text = fs.readTextSync(filePath);
        text = text.trim();

        if (text.length === 0) continue;

        let lines = text.split(/\r?\n/);
        let firstValidLineIndex = lines.findIndex(line => line.trim() !== '');

        if (firstValidLineIndex !== -1) {
          let title = lines[firstValidLineIndex].trim();
          let content = lines.slice(firstValidLineIndex + 1).join('\n').trim();
          let hexId = counter.toString(16) + '_' + Date.now().toString(16);

          loadedSongs.push({ id: hexId, title: title, content: content });
          counter++;
        }
      }

      this.songsList = loadedSongs;
      if (loadedSongs.length === 0) {
        this.errorMessage = "Pusto. Zsynchronizuj z GitHubem!";
      } else {
        this.errorMessage = '';
      }

    } catch (error) {
      this.errorMessage = `Błąd odczytu: ${error}`;
    }
  }

  // 2. FUNKCJA POBIERAJĄCA Z GITHUBA
  async syncWithGitHub() {
    this.isLoading = true;
    this.errorMessage = 'Pobieranie listy...';

    // To jest główny trzon Twoich linków z GitHuba (bez nazwy konkretnego pliku na końcu)
    //let baseUrl = "https://raw.githubusercontent.com/kazikku/Teskty_GuitarChordsAPP/main/";
    let baseUrl = "https://raw.githubusercontent.com/kazikku/Teskty_GuitarChordsAPP/refs/heads/main/";

    // Najpierw pobieramy plik ze spisem treści
    let indexUrl = baseUrl + "index.txt";
    let indexRequest = http.createHttp();

    try {
      let indexResponse = await indexRequest.request(indexUrl, {
        method: http.RequestMethod.GET,
        connectTimeout: 5000,
        readTimeout: 5000
      });

      if (indexResponse.responseCode !== 200) {
        this.errorMessage = "Nie znaleziono pliku index.txt na GitHubie!";
        return;
      }

      // Odczytujemy listę z index.txt i usuwamy puste linie
      let indexText = indexResponse.result as string;
      let fileNames = indexText.split(/\r?\n/).map(name => name.trim()).filter(name => name.length > 0);

      if (fileNames.length === 0) {
        this.errorMessage = "Plik index.txt jest pusty.";
        return;
      }

      let context = getContext(this) as common.UIAbilityContext;
      let successCount = 0;

      // PĘTLA POBIERAJĄCA KAŻDY PLIK Z LISTY
      for (let fileName of fileNames) {
        this.errorMessage = `Pobieram: ${fileName}...`;

        let fileUrl = baseUrl + fileName;
        // Ważne: dla każdego pliku tworzymy nowe żądanie HTTP, by zapobiec błędom asynchroniczności
        let fileRequest = http.createHttp();

        try {
          let fileResponse = await fileRequest.request(fileUrl, { method: http.RequestMethod.GET });

          if (fileResponse.responseCode === 200) {
            let downloadedText = fileResponse.result as string;
            let filePath = context.filesDir + "/" + fileName;

            // Używamy flagi TRUNC (Truncate), aby przy aktualizacji starego pliku całkowicie go nadpisać
            let file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
            fs.writeSync(file.fd, downloadedText);
            fs.closeSync(file);

            successCount++;
          }
        } catch (e) {
          console.error(`Błąd podczas pobierania ${fileName}: ${e}`);
        } finally {
          fileRequest.destroy(); // Czyszczenie pamięci po każdym pliku
        }
      }

      // Po zakończeniu pętli odświeżamy listę na ekranie
      this.loadSongsFromWatchMemory();

      // Wyświetlamy małe podsumowanie dla użytkownika
      this.errorMessage = `Pobrano pomyślnie: ${successCount} z ${fileNames.length}`;

    } catch (error) {
      this.errorMessage = `Brak internetu/Błąd: ${error}`;
    } finally {
      this.isLoading = false;
      indexRequest.destroy();
    }
  }

  build() {
    Column() {
      // Text('Mój Śpiewnik')
      //   .fontSize(20)
      //   .fontWeight(FontWeight.Bold)
      //   .fontColor(Color.White)
      //   .margin({ top: 25, bottom: 10 })

      if (this.isLoading) {
        Column() {
          // Zmiana 2: kółko ładowania dopasowuje się do tła
          LoadingProgress().width(40).height(40).color(this.isDarkTheme ? Color.White : Color.Black)
        }.layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        List({ space: 10 }) {
          ForEach(this.songsList, (song: Song) => {
            ListItem() {
              Column() {
                Text(song.title)
                  .fontSize(10)
                  .fontColor('#45a2f8')
                  .fontWeight(FontWeight.Bold)

                // Text(song.content)
                //   .fontSize(13)
                //   .fontColor(Color.Gray)
                //   .maxLines(2)
                //   .margin({ top: 5 })

              // DODAJEMY ONCLICK TUTAJ:
              .onClick(() => {
                router.pushUrl({
                  url: 'pages/SongDetail', // Ścieżka do nowego ekranu
                  params: {
                    title: song.title,
                    content: song.content
                  }
                }).catch((err: Error) => {
                  console.error(`Błąd nawigacji: ${err.message}`);
                });

              })

              }

              .alignItems(HorizontalAlign.Start)
              .padding(12)
              .width('100%')
              .backgroundColor(this.isDarkTheme ? '#1e1e1e' : '#f0f0f0')
              .borderRadius(8)
            }

          }, (song: Song) => song.id)

          ListItem(){
            Column(){
              Button('Pobierz z GitHuba')
                .fontSize(10)
                .width('70%')
                .margin({ bottom: 5})
                .backgroundColor(this.isDarkTheme ? '#555555' : '#e0e0e0')
                .onClick(() => {
                  this.syncWithGitHub();
                })
              Button('Ustawienia')
                .width('70%')
                .fontSize(10)
                .margin({ bottom: 10 })
                .backgroundColor(this.isDarkTheme ? '#555555' : '#e0e0e0') // Szary neutralny kolor
                .onClick(() => {
                  router.pushUrl({
                    url: 'pages/Settings'
                  }).catch((err: Error) => {
                    console.error(`Błąd: ${err.message}`);
                  });
                })
              if (this.errorMessage !== '') {
                Text(this.errorMessage)
                  .fontSize(12)
                  // Prosty trik: jeśli to tekst o pobraniu, dajemy zielony. W przeciwnym razie czerwony.
                  //.backgroundColor(this.isDarkTheme ? '#555555' : '#e0e0e0')
                  .textAlign(TextAlign.Center)
                  .padding({ top: 10, bottom: 5 })
                  .width('80%')
              }
            }

            .width('100%')
          }
        }
        .width('90%')
        .layoutWeight(1)
        .margin({top:30})

      }



    }

    .width('100%')
    .height('100%')
    .padding({ bottom: 20 })
    .backgroundColor(this.isDarkTheme ? Color.Black : Color.White)
  }

}