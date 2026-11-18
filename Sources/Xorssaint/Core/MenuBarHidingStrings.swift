// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

struct MenuBarHidingStrings {
    let title: String
    let hubDescription: String
    let pageDescription: String
    let masterToggle: String
    let masterCaption: String
    let listTitle: String
    let listCaption: String
    let refresh: String
    let emptyList: String
    let hiddenNotRunning: String
    let revealAll: String
    let restoreHiding: String
    let limitationsTitle: String
    let limitationApps: String
    let limitationSystem: String
    let limitationSideEffects: String
    let limitationQuit: String
    let unavailableOS: String
    let unavailableFramework: String
    let unavailableLocation: String
}

extension FeatureStrings {
    static func menuBarHiding(_ language: AppLanguage) -> MenuBarHidingStrings {
        switch language {
        case .enUS: return .enUS
        case .ptBR: return .ptBR
        case .tr: return .tr
        case .ru: return .ru
        case .es: return .es
        case .sk: return .sk
        case .de: return .de
        case .fr: return .fr
        case .it: return .it
        case .ja: return .ja
        case .ko: return .ko
        case .zhHans: return .zhHans
        case .zhTW: return .zhTW
        case .zhHK: return .zhHK
        case .uk: return .uk
        }
    }
}

extension MenuBarHidingStrings {
    static let enUS = MenuBarHidingStrings(
        title: "Menu Bar Hiding",
        hubDescription: "Hide the menu bar icons of the apps you pick; everything else stays.",
        pageDescription: "Choose which apps’ menu bar icons stay hidden on macOS 27.",
        masterToggle: "Hide the selected apps’ menu bar icons",
        masterCaption: "Icons come back when this is off, or from the menu bar icon’s menu.",
        listTitle: "Apps",
        listCaption: "Running apps. Hiding applies per app, not per icon.",
        refresh: "Refresh",
        emptyList: "No running apps to list yet.",
        hiddenNotRunning: "Selected but not running",
        revealAll: "Show All Menu Bar Icons",
        restoreHiding: "Hide Selected Icons Again",
        limitationsTitle: "Notes",
        limitationApps: "Hiding works per app: an app with several icons hides and returns as a group.",
        limitationSystem: "System items (clock, Wi-Fi, Control Center) always stay visible.",
        limitationSideEffects: "While hiding is on, clicking the clock does not open Notification Center and the microphone/camera capsule is hidden.",
        limitationQuit: "Quitting Xorssaint brings every icon back.",
        unavailableOS: "Requires macOS 27 or newer",
        unavailableFramework: "This macOS build does not expose the menu bar visibility restriction",
        unavailableLocation: "Move Xorssaint into the Applications folder to enable hiding"
    )

    static let zhHans = MenuBarHidingStrings(
        title: "菜单栏图标隐藏",
        hubDescription: "隐藏你选中的 App 的菜单栏图标，其余保持原样。",
        pageDescription: "在 macOS 27 上选择哪些 App 的菜单栏图标保持隐藏。",
        masterToggle: "隐藏所选 App 的菜单栏图标",
        masterCaption: "关闭后图标会回来；也可以从菜单栏图标的右键菜单临时放出。",
        listTitle: "App",
        listCaption: "当前运行中的 App。隐藏以 App 为单位，不按单个图标。",
        refresh: "刷新",
        emptyList: "还没有可列出的运行中 App。",
        hiddenNotRunning: "已选择但未运行",
        revealAll: "显示全部菜单栏图标",
        restoreHiding: "恢复隐藏所选图标",
        limitationsTitle: "说明",
        limitationApps: "隐藏以 App 为单位：一个 App 有多个图标时一起隐藏、一起恢复。",
        limitationSystem: "系统项（时钟、Wi-Fi、控制中心）始终显示。",
        limitationSideEffects: "隐藏期间点击时钟不会打开通知中心，麦克风/摄像头提示胶囊也会被隐藏。",
        limitationQuit: "退出 Xorssaint 后所有图标都会恢复显示。",
        unavailableOS: "需要 macOS 27 或更新版本",
        unavailableFramework: "当前 macOS 版本未提供菜单栏可见性限制",
        unavailableLocation: "请把 Xorssaint 移到“应用程序”文件夹后再启用隐藏"
    )

    static let zhTW = MenuBarHidingStrings(
        title: "選單列圖示隱藏",
        hubDescription: "隱藏你選取的 App 的選單列圖示，其餘保持原狀。",
        pageDescription: "在 macOS 27 上選擇哪些 App 的選單列圖示保持隱藏。",
        masterToggle: "隱藏所選 App 的選單列圖示",
        masterCaption: "關閉後圖示會回來；也可以從選單列圖示的右鍵選單暫時放出。",
        listTitle: "App",
        listCaption: "目前執行中的 App。隱藏以 App 為單位，不依個別圖示。",
        refresh: "重新整理",
        emptyList: "還沒有可列出的執行中 App。",
        hiddenNotRunning: "已選取但未執行",
        revealAll: "顯示全部選單列圖示",
        restoreHiding: "恢復隱藏所選圖示",
        limitationsTitle: "說明",
        limitationApps: "隱藏以 App 為單位：一個 App 有多個圖示時會一起隱藏、一起恢復。",
        limitationSystem: "系統項目（時鐘、Wi-Fi、控制中心）一律顯示。",
        limitationSideEffects: "隱藏期間點按時鐘不會打開通知中心，麥克風/攝影機提示膠囊也會被隱藏。",
        limitationQuit: "結束 Xorssaint 後所有圖示都會恢復顯示。",
        unavailableOS: "需要 macOS 27 或更新版本",
        unavailableFramework: "目前的 macOS 版本未提供選單列可見性限制",
        unavailableLocation: "請把 Xorssaint 移到「應用程式」資料夾後再啟用隱藏"
    )

    static let zhHK = MenuBarHidingStrings(
        title: "選單列圖示隱藏",
        hubDescription: "隱藏你揀選嘅 App 嘅選單列圖示，其餘保持原狀。",
        pageDescription: "喺 macOS 27 上揀選邊啲 App 嘅選單列圖示保持隱藏。",
        masterToggle: "隱藏所揀 App 嘅選單列圖示",
        masterCaption: "閂咗之後圖示會返嚟；亦可以喺選單列圖示嘅右鍵選單暫時放出。",
        listTitle: "App",
        listCaption: "目前運行中嘅 App。隱藏以 App 為單位，唔係逐個圖示。",
        refresh: "重新整理",
        emptyList: "仲未有可列出嘅運行中 App。",
        hiddenNotRunning: "已揀選但未運行",
        revealAll: "顯示全部選單列圖示",
        restoreHiding: "恢復隱藏所揀圖示",
        limitationsTitle: "說明",
        limitationApps: "隱藏以 App 為單位：一個 App 有多個圖示時會一齊隱藏、一齊恢復。",
        limitationSystem: "系統項目（時鐘、Wi-Fi、控制中心）一律顯示。",
        limitationSideEffects: "隱藏期間撳時鐘唔會開通知中心，咪高峰/鏡頭提示膠囊都會被隱藏。",
        limitationQuit: "結束 Xorssaint 之後所有圖示都會恢復顯示。",
        unavailableOS: "需要 macOS 27 或更新版本",
        unavailableFramework: "目前嘅 macOS 版本未提供選單列可見性限制",
        unavailableLocation: "請將 Xorssaint 移去「應用程式」資料夾再啟用隱藏"
    )

    static let ja = MenuBarHidingStrings(
        title: "メニューバーアイコンを隠す",
        hubDescription: "選んだ App のメニューバーアイコンを隠し、それ以外はそのまま残します。",
        pageDescription: "macOS 27 で隠したい App のメニューバーアイコンを選びます。",
        masterToggle: "選んだ App のメニューバーアイコンを隠す",
        masterCaption: "オフにするとアイコンが戻ります。メニューバーアイコンのメニューから一時的に表示もできます。",
        listTitle: "App",
        listCaption: "実行中の App。非表示は App 単位で、アイコンごとではありません。",
        refresh: "再読み込み",
        emptyList: "表示できる実行中の App がまだありません。",
        hiddenNotRunning: "選択済みだが実行していない",
        revealAll: "メニューバーのアイコンをすべて表示",
        restoreHiding: "選んだアイコンを再び隠す",
        limitationsTitle: "注意",
        limitationApps: "非表示は App 単位です。複数のアイコンを持つ App はまとめて隠れ、まとめて戻ります。",
        limitationSystem: "システム項目（時計、Wi-Fi、コントロールセンター）は常に表示されます。",
        limitationSideEffects: "非表示の間、時計をクリックしても通知センターが開かず、マイク/カメラの表示も隠されます。",
        limitationQuit: "Xorssaint を終了するとすべてのアイコンが戻ります。",
        unavailableOS: "macOS 27 以降が必要です",
        unavailableFramework: "この macOS にはメニューバー表示の制限がありません",
        unavailableLocation: "非表示を有効にするには Xorssaint を「アプリケーション」フォルダに移動してください"
    )

    static let ko = MenuBarHidingStrings(
        title: "메뉴 막대 아이콘 숨기기",
        hubDescription: "선택한 App의 메뉴 막대 아이콘을 숨기고 나머지는 그대로 둡니다.",
        pageDescription: "macOS 27에서 숨길 App의 메뉴 막대 아이콘을 선택합니다.",
        masterToggle: "선택한 App의 메뉴 막대 아이콘 숨기기",
        masterCaption: "끄면 아이콘이 돌아옵니다. 메뉴 막대 아이콘 메뉴에서 잠시 표시할 수도 있습니다.",
        listTitle: "App",
        listCaption: "실행 중인 App. 숨기기는 아이콘 단위가 아니라 App 단위로 적용됩니다.",
        refresh: "새로 고침",
        emptyList: "표시할 실행 중인 App이 아직 없습니다.",
        hiddenNotRunning: "선택했으나 실행 중이 아님",
        revealAll: "메뉴 막대 아이콘 모두 보기",
        restoreHiding: "선택한 아이콘 다시 숨기기",
        limitationsTitle: "참고",
        limitationApps: "숨기기는 App 단위입니다. 아이콘이 여러 개인 App은 함께 숨겨지고 함께 돌아옵니다.",
        limitationSystem: "시스템 항목(시계, Wi-Fi, 제어 센터)은 항상 표시됩니다.",
        limitationSideEffects: "숨기는 동안 시계를 클릭해도 알림 센터가 열리지 않고 마이크/카메라 표시도 숨겨집니다.",
        limitationQuit: "Xorssaint를 종료하면 모든 아이콘이 돌아옵니다.",
        unavailableOS: "macOS 27 이상이 필요합니다",
        unavailableFramework: "이 macOS에는 메뉴 막대 표시 제한이 없습니다",
        unavailableLocation: "숨기를 쓰려면 Xorssaint를 응용 프로그램 폴더로 옮기세요"
    )

    static let de = MenuBarHidingStrings(
        title: "Menüleisten-Symbole ausblenden",
        hubDescription: "Blendet die Menüleisten-Symbole der gewählten Apps aus, alle anderen bleiben.",
        pageDescription: "Wähle auf macOS 27, welche App-Symbole in der Menüleiste verborgen bleiben.",
        masterToggle: "Menüleisten-Symbole der gewählten Apps ausblenden",
        masterCaption: "Aus macht die Symbole sichtbar; das Menü des Menüleisten-Symbols zeigt sie vorübergehend.",
        listTitle: "Apps",
        listCaption: "Laufende Apps. Das Ausblenden gilt je App, nicht je Symbol.",
        refresh: "Aktualisieren",
        emptyList: "Noch keine laufenden Apps vorhanden.",
        hiddenNotRunning: "Gewählt, aber nicht aktiv",
        revealAll: "Alle Menüleisten-Symbole zeigen",
        restoreHiding: "Gewählte Symbole wieder ausblenden",
        limitationsTitle: "Hinweise",
        limitationApps: "Das Ausblenden gilt je App: Eine App mit mehreren Symbolen verschwindet und kehrt als Gruppe zurück.",
        limitationSystem: "Systemelemente (Uhr, WLAN, Kontrollzentrum) bleiben immer sichtbar.",
        limitationSideEffects: "Während des Ausblendens öffnet ein Klick auf die Uhr nicht die Mitteilungszentrale, und die Mikrofon-/Kamera-Anzeige wird verborgen.",
        limitationQuit: "Beim Beenden von Xorssaint kehren alle Symbole zurück.",
        unavailableOS: "Erfordert macOS 27 oder neuer",
        unavailableFramework: "Diese macOS-Version bietet die Menüleisten-Beschränkung nicht",
        unavailableLocation: "Zum Ausblenden Xorssaint in den Programme-Ordner legen"
    )

    static let fr = MenuBarHidingStrings(
        title: "Masquer les icônes de la barre de menus",
        hubDescription: "Masque les icônes de barre de menus des apps choisies ; le reste ne change pas.",
        pageDescription: "Choisis sur macOS 27 quelles icônes de barre de menus restent masquées.",
        masterToggle: "Masquer les icônes de barre de menus des apps choisies",
        masterCaption: "Désactivé, les icônes reviennent ; le menu de l’icône les affiche aussi temporairement.",
        listTitle: "Apps",
        listCaption: "Apps en cours d’exécution. Le masquage s’applique par app, pas par icône.",
        refresh: "Actualiser",
        emptyList: "Aucune app en cours à lister pour l’instant.",
        hiddenNotRunning: "Choisies mais inactive",
        revealAll: "Afficher toutes les icônes de la barre de menus",
        restoreHiding: "Masquer à nouveau les icônes choisies",
        limitationsTitle: "Remarques",
        limitationApps: "Le masquage se fait par app : une app à plusieurs icônes disparaît et revient en groupe.",
        limitationSystem: "Les éléments système (horloge, Wi-Fi, centre de contrôle) restent toujours visibles.",
        limitationSideEffects: "Pendant le masquage, cliquer sur l’horloge n’ouvre pas le centre de notifications et la pastille micro/caméra est masquée.",
        limitationQuit: "Quitter Xorssaint ramène toutes les icônes.",
        unavailableOS: "Nécessite macOS 27 ou ultérieur",
        unavailableFramework: "Cette version de macOS n’expose pas la restriction de barre de menus",
        unavailableLocation: "Déplace Xorssaint dans le dossier Applications pour activer le masquage"
    )

    static let es = MenuBarHidingStrings(
        title: "Ocultar iconos de la barra de menús",
        hubDescription: "Oculta los iconos de la barra de menús de las apps que elijas; el resto no cambia.",
        pageDescription: "Elige en macOS 27 qué iconos de la barra de menús permanecen ocultos.",
        masterToggle: "Ocultar los iconos de la barra de menús de las apps elegidas",
        masterCaption: "Al apagarlo los iconos vuelven; el menú del icono también los muestra un momento.",
        listTitle: "Apps",
        listCaption: "Apps en ejecución. El ocultado se aplica por app, no por icono.",
        refresh: "Actualizar",
        emptyList: "Aún no hay apps en ejecución que listar.",
        hiddenNotRunning: "Elegidas pero no en ejecución",
        revealAll: "Mostrar todos los iconos de la barra de menús",
        restoreHiding: "Volver a ocultar los iconos elegidos",
        limitationsTitle: "Notas",
        limitationApps: "El ocultado va por app: una app con varios iconos se oculta y vuelve en grupo.",
        limitationSystem: "Los elementos del sistema (reloj, Wi-Fi, Centro de Control) siempre permanecen visibles.",
        limitationSideEffects: "Mientras ocultas, pulsar el reloj no abre el Centro de Notificaciones y la cápsula de micrófono/cámara se oculta.",
        limitationQuit: "Al salir de Xorssaint vuelven todos los iconos.",
        unavailableOS: "Requiere macOS 27 o posterior",
        unavailableFramework: "Esta versión de macOS no ofrece la restricción de la barra de menús",
        unavailableLocation: "Mueve Xorssaint a la carpeta Aplicaciones para activar el ocultado"
    )

    static let it = MenuBarHidingStrings(
        title: "Nascondi le icone della barra dei menu",
        hubDescription: "Nasconde le icone della barra dei menu delle app scelte; il resto resta invariato.",
        pageDescription: "Scegli su macOS 27 quali icone della barra dei menu restano nascoste.",
        masterToggle: "Nascondi le icone della barra dei menu delle app scelte",
        masterCaption: "Se disattivato le icone tornano; dal menu dell’icona puoi mostrarle temporaneamente.",
        listTitle: "App",
        listCaption: "App in esecuzione. La nascita vale per app, non per singola icona.",
        refresh: "Aggiorna",
        emptyList: "Ancora nessuna app in esecuzione da elencare.",
        hiddenNotRunning: "Scelte ma non in esecuzione",
        revealAll: "Mostra tutte le icone della barra dei menu",
        restoreHiding: "Nascondi di nuovo le icone scelte",
        limitationsTitle: "Note",
        limitationApps: "La nascita vale per app: un’app con più icone sparisce e torna in gruppo.",
        limitationSystem: "Gli elementi di sistema (orologio, Wi-Fi, Centro di Controllo) restano sempre visibili.",
        limitationSideEffects: "Mentre è attiva, cliccare l’orologio non apre il Centro Notifiche e la capsula microfono/fotocamera viene nascosta.",
        limitationQuit: "Uscendo da Xorssaint tutte le icone tornano visibili.",
        unavailableOS: "Richiede macOS 27 o successivo",
        unavailableFramework: "Questa versione di macOS non espone la restrizione della barra dei menu",
        unavailableLocation: "Sposta Xorssaint nella cartella Applicazioni per attivare la nascita"
    )

    static let ptBR = MenuBarHidingStrings(
        title: "Ocultar ícones da barra de menus",
        hubDescription: "Oculta os ícones da barra de menus dos apps escolhidos; o resto fica como está.",
        pageDescription: "Escolha no macOS 27 quais ícones da barra de menus ficam ocultos.",
        masterToggle: "Ocultar os ícones da barra de menus dos apps escolhidos",
        masterCaption: "Desligado, os ícones voltam; o menu do ícone também os mostra por um momento.",
        listTitle: "Apps",
        listCaption: "Apps em execução. A ocultação vale por app, não por ícone.",
        refresh: "Atualizar",
        emptyList: "Ainda não há apps em execução para listar.",
        hiddenNotRunning: "Escolhidos, mas não em execução",
        revealAll: "Mostrar todos os ícones da barra de menus",
        restoreHiding: "Ocultar novamente os ícones escolhidos",
        limitationsTitle: "Observações",
        limitationApps: "A ocultação vale por app: um app com vários ícones some e volta em grupo.",
        limitationSystem: "Itens do sistema (relógio, Wi-Fi, Central de Controle) ficam sempre visíveis.",
        limitationSideEffects: "Enquanto oculta, clicar no relógio não abre a Central de Notificações e a cápsula de microfone/câmera é ocultada.",
        limitationQuit: "Sair do Xorssaint traz todos os ícones de volta.",
        unavailableOS: "Requer macOS 27 ou posterior",
        unavailableFramework: "Esta versão do macOS não expõe a restrição da barra de menus",
        unavailableLocation: "Mova o Xorssaint para a pasta Aplicativos para ativar a ocultação"
    )

    static let tr = MenuBarHidingStrings(
        title: "Menü çubuğu simgelerini gizle",
        hubDescription: "Seçtiğin uygulamaların menü çubuğu simgelerini gizler; gerisi aynı kalır.",
        pageDescription: "macOS 27’de hangi uygulamaların menü çubuğu simgelerinin gizli kalacağını seç.",
        masterToggle: "Seçili uygulamaların menü çubuğu simgelerini gizle",
        masterCaption: "Kapatınca simgeler geri gelir; simgenin menüsünden geçici olarak da gösterilebilir.",
        listTitle: "Uygulamalar",
        listCaption: "Çalışan uygulamalar. Gizleme uygulama başınadır, simge başına değil.",
        refresh: "Yenile",
        emptyList: "Henüz listelenecek çalışan uygulama yok.",
        hiddenNotRunning: "Seçili ama çalışmıyor",
        revealAll: "Tüm menü çubuğu simgelerini göster",
        restoreHiding: "Seçili simgeleri yeniden gizle",
        limitationsTitle: "Notlar",
        limitationApps: "Gizleme uygulama başınadır: birkaç simgesi olan uygulama topluca gizlenir ve döner.",
        limitationSystem: "Sistem öğeleri (saat, Wi-Fi, Denetim Merkezi) her zaman görünür kalır.",
        limitationSideEffects: "Gizleme açıkken saate tıklamak Bildirim Merkezi’ni açmaz ve mikrofon/kamera kapsülü gizlenir.",
        limitationQuit: "Xorssaint’ten çıkınca tüm simgeler geri gelir.",
        unavailableOS: "macOS 27 veya üstü gerekir",
        unavailableFramework: "Bu macOS sürümü menü çubuğu kısıtlaması sunmuyor",
        unavailableLocation: "Gizlemeyi etkinleştirmek için Xorssaint’i Uygulamalar klasörüne taşı"
    )

    static let ru = MenuBarHidingStrings(
        title: "Скрытие значков в строке меню",
        hubDescription: "Скрывает значки в строке меню у выбранных приложений; остальные не трогает.",
        pageDescription: "Выберите в macOS 27, у каких приложений значки в строке меню останутся скрытыми.",
        masterToggle: "Скрывать значки в строке меню у выбранных приложений",
        masterCaption: "При выключении значки возвращаются; из меню значка их можно временно показать.",
        listTitle: "Приложения",
        listCaption: "Работающие приложения. Скрытие применяется по приложению, а не по значку.",
        refresh: "Обновить",
        emptyList: "Пока нет работающих приложений для списка.",
        hiddenNotRunning: "Выбраны, но не работают",
        revealAll: "Показать все значки в строке меню",
        restoreHiding: "Снова скрыть выбранные значки",
        limitationsTitle: "Примечания",
        limitationApps: "Скрытие идёт по приложению: приложение с несколькими значками скрывается и возвращается целиком.",
        limitationSystem: "Системные элементы (часы, Wi-Fi, Пункт управления) всегда остаются видимыми.",
        limitationSideEffects: "Пока скрытие включено, щелчок по часам не открывает Центр уведомлений, а индикатор микрофона/камеры скрывается.",
        limitationQuit: "После выхода из Xorssaint все значки возвращаются.",
        unavailableOS: "Требуется macOS 27 или новее",
        unavailableFramework: "Эта сборка macOS не даёт ограничения строки меню",
        unavailableLocation: "Перенесите Xorssaint в папку «Программы», чтобы включить скрытие"
    )

    static let uk = MenuBarHidingStrings(
        title: "Приховування значків у рядку меню",
        hubDescription: "Ховає значки у рядку меню у вибраних програм; решта лишається як є.",
        pageDescription: "Оберіть у macOS 27, у яких програм значки в рядку меню лишатимуться прихованими.",
        masterToggle: "Ховати значки у рядку меню у вибраних програмах",
        masterCaption: "Вимкнення повертає значки; з меню значка їх можна тимчасово показати.",
        listTitle: "Програми",
        listCaption: "Працюючі програми. Приховування діє на програму, а не на окремий значок.",
        refresh: "Оновити",
        emptyList: "Ще немає працюючих програм для списку.",
        hiddenNotRunning: "Вибрані, але не працюють",
        revealAll: "Показати всі значки в рядку меню",
        restoreHiding: "Знову сховати вибрані значки",
        limitationsTitle: "Примітки",
        limitationApps: "Приховування діє на програму: програма з кількома значками ховається і повертається разом.",
        limitationSystem: "Системні елементи (годинник, Wi-Fi, Пункт керування) завжди видимі.",
        limitationSideEffects: "Під час приховування клацання на годиннику не відкриває Центр сповіщень, а індикатор мікрофона/камери ховається.",
        limitationQuit: "Після виходу з Xorssaint усі значки повертаються.",
        unavailableOS: "Потрібен macOS 27 або новіший",
        unavailableFramework: "Ця збірка macOS не надає обмеження рядка меню",
        unavailableLocation: "Щоб увімкнути приховування, перенесіть Xorssaint у теку «Програми»"
    )

    static let sk = MenuBarHidingStrings(
        title: "Skrytie ikon v lište menu",
        hubDescription: "Skryje ikony v lište menu vybraných aplikácií; ostatné zostanú.",
        pageDescription: "Vyber na macOS 27, ktorých ikony v lište menu zostanú skryté.",
        masterToggle: "Skryť ikony v lište menu vybraných aplikácií",
        masterCaption: "Po vypnutí sa ikony vrátia; z menu ikony ich možno chvíľu aj zobraziť.",
        listTitle: "Aplikácie",
        listCaption: "Bežiace aplikácie. Skrývanie platí podľa aplikácie, nie podľa ikony.",
        refresh: "Obnoviť",
        emptyList: "Zatiaľ nie sú žiadne bežiace aplikácie na zobrazenie.",
        hiddenNotRunning: "Vybrané, ale nebežia",
        revealAll: "Zobraziť všetky ikony v lište menu",
        restoreHiding: "Znova skryť vybrané ikony",
        limitationsTitle: "Poznámky",
        limitationApps: "Skrývanie platí podľa aplikácie: aplikácia s viacerými ikonami sa skryje a vráti ako celok.",
        limitationSystem: "Systémové položky (hodiny, Wi-Fi, Ovládacie centrum) sú vždy viditeľné.",
        limitationSideEffects: "Počas skrývania kliknutie na hodiny neotvorí Centrum oznámení a kapsula mikrofónu/kamery sa skryje.",
        limitationQuit: "Po ukončení Xorssaint sa všetky ikony vrátia.",
        unavailableOS: "Vyžaduje macOS 27 alebo novší",
        unavailableFramework: "Toto vydanie macOS neposkytuje obmedzenie lišty menu",
        unavailableLocation: "Na povolenie skrývania presuň Xorssaint do priečinka Aplikácie"
    )
}
