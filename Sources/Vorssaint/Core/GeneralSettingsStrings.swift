// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// Plain-language copy for the General page: one short line per control and
/// one per panel section, so the page explains itself without paragraphs.
struct GeneralSettingsStrings {
    let pageDescription: String
    let appearanceCaption: String
    let launchAtLoginCaption: String
    let liquidGlassCaption: String
    let liquidGlassOtherWindows: String
    let panelIntro: String
    let panelReorderHint: String
    let clockTitle: String
    let clockCaption: String
    let clockFormatTitle: String
    let clockFormatCaption: String
    let clockFormatReset: String
    let clockPreviewLabel: String
    let clockFormatHelp: String
    let clockSizeTitle: String
    let clockSizeCaption: String
    let menuBarIconTitle: String
    let menuBarIconCaption: String
    let menuBarIconOther: String
    let menuBarIconOtherCaption: String
    let menuBarIconUnknown: String
    let menuBarIconReset: String
    let iconMissingTitle: String
    let iconMissingCaption: String
    let sectionKeepAwake: String
    let sectionDisplays: String
    let sectionMixer: String
    let sectionSystem: String
    let sectionNetwork: String
    let sectionDisks: String
    let sectionPower: String
    let sectionFanControl: String
    let sectionUtilities: String
    let sectionControls: String
    let sectionToggles: String
}

extension FeatureStrings {
    static func generalSettings(_ language: AppLanguage) -> GeneralSettingsStrings {
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
        case .uk: return .uk
        case .zhHans: return .zhHans
        case .zhTW: return .zhTW
        case .zhHK: return .zhHK
        }
    }
}

extension GeneralSettingsStrings {
    static let uk = GeneralSettingsStrings(
        pageDescription: "Як запускається Vorssaint, який має вигляд і що показує панель на смузі меню.",
        appearanceCaption: "Стосується лише вікон і панелей Vorssaint, а не всього Mac.",
        launchAtLoginCaption: "Автоматично відкривається щоразу після запуску Mac.",
        liquidGlassCaption: "Прозорі панелі з ефектом скла.",
        liquidGlassOtherWindows: "Інші вікна й панелі",
        panelIntro: "Натисніть значок Vorssaint на смузі меню, щоб відкрити панель. Вкладки розташовані в такому порядку.",
        panelReorderHint: "Перетягуйте, щоб змінити порядок. Вимкніть те, що вам не потрібно.",
        clockTitle: "Годинник у смузі меню",
        clockCaption: "Показує дату й час замість значка. Значок повертається під час оновлень, вимкненого мікрофона або Keep Awake.",
        clockFormatTitle: "Формат дати й часу",
        clockFormatCaption: "Шаблон дати Unicode. Залиште порожнім, щоб використовувати формат за замовчуванням.",
        clockFormatReset: "Використати типовий",
        clockPreviewLabel: "Попередній перегляд",
        clockFormatHelp: "Шаблони формату дати (Unicode TR35)",
        clockSizeTitle: "Розмір шрифту годинника",
        clockSizeCaption: "12–16 pt. Типове значення 13 pt збігається зі смугою меню системи.",
        menuBarIconTitle: "Значок на смузі меню",
        menuBarIconCaption: "Виберіть значок, який Vorssaint показує на смузі меню.",
        menuBarIconOther: "Інший символ",
        menuBarIconOtherCaption: "Введіть назву будь-якого символу SF Symbols. Залиште поле порожнім, щоб використовувати значок Vorssaint.",
        menuBarIconUnknown: "На цьому Mac немає символу з такою назвою.",
        menuBarIconReset: "Використовувати значок Vorssaint",
        iconMissingTitle: "Не можете знайти значок?",
        iconMissingCaption: "Переповнена смуга меню може його приховати, особливо на Mac із вирізом.",
        sectionKeepAwake: "Не дає Mac заснути стільки, скільки потрібно.",
        sectionDisplays: "Яскравість екранів.",
        sectionMixer: "Гучність кожної програми на окремому повзунку.",
        sectionSystem: "Процесор, графіка й пам’ять з першого погляду.",
        sectionNetwork: "Швидкість інтернету та програми, що ним користуються.",
        sectionDisks: "Вільне місце й активність дисків.",
        sectionPower: "Акумулятор, заряджання та споживання енергії.",
        sectionFanControl: "Швидкість вентиляторів і власна крива їхньої роботи.",
        sectionUtilities: "Знімки екрана, очищення, оновлення та інші інструменти.",
        sectionControls: "Перемикачі функцій миші, клавіатури й вікон.",
        sectionToggles: "Дії одним натисканням, як-от темний режим і вимкнення мікрофона."
    )

    static let enUS = GeneralSettingsStrings(
        pageDescription: "How Vorssaint starts, how it looks and what its menu bar panel shows.",
        appearanceCaption: "Applies to Vorssaint’s own windows and panels, not to the whole Mac.",
        launchAtLoginCaption: "Opens by itself every time you turn on your Mac.",
        liquidGlassCaption: "See-through, glass-like panels.",
        liquidGlassOtherWindows: "Other windows and panels",
        panelIntro: "Click Vorssaint’s icon in the menu bar to open the panel. Its tabs appear in this order.",
        panelReorderHint: "Drag to reorder. Switch off anything you don’t need.",
        clockTitle: "Menu bar clock",
        clockCaption: "Shows the date and time instead of the icon. The icon still returns for updates, a muted microphone or Keep Awake.",
        clockFormatTitle: "Date and time format",
        clockFormatCaption: "A Unicode date pattern. Leave it empty to use the default.",
        clockFormatReset: "Use default",
        clockPreviewLabel: "Preview",
        clockFormatHelp: "Date format patterns (Unicode TR35)",
        clockSizeTitle: "Clock font size",
        clockSizeCaption: "12–16 pt. The default, 13 pt, matches the system menu bar.",
        menuBarIconTitle: "Menu bar icon",
        menuBarIconCaption: "Choose the icon Vorssaint shows in the menu bar.",
        menuBarIconOther: "Other symbol",
        menuBarIconOtherCaption: "Type the name of any SF Symbol. Leave it empty to use the Vorssaint icon.",
        menuBarIconUnknown: "This Mac has no symbol with that name.",
        menuBarIconReset: "Use the Vorssaint icon",
        iconMissingTitle: "Can’t find the icon?",
        iconMissingCaption: "A crowded menu bar can hide it, especially on Macs with a notch.",
        sectionKeepAwake: "Keeps your Mac awake for as long as you want.",
        sectionDisplays: "Brightness of your displays.",
        sectionMixer: "Volume of each app, one slider each.",
        sectionSystem: "Processor, graphics and memory at a glance.",
        sectionNetwork: "Internet speed and which apps are using it.",
        sectionDisks: "Free space and disk activity.",
        sectionPower: "Battery, charging and power use.",
        sectionFanControl: "Fan speeds and your own fan curve.",
        sectionUtilities: "Screenshots, cleaner, updates and other tools.",
        sectionControls: "Switches for mouse, keyboard and window features.",
        sectionToggles: "One-click actions like dark mode and muting the mic."
    )

    static let ptBR = GeneralSettingsStrings(
        pageDescription: "Como o Vorssaint inicia, como ele aparece e o que o painel da barra de menus mostra.",
        appearanceCaption: "Vale para as janelas e painéis do Vorssaint, não para o Mac inteiro.",
        launchAtLoginCaption: "Abre sozinho toda vez que você liga o Mac.",
        liquidGlassCaption: "Painéis translúcidos, com aparência de vidro.",
        liquidGlassOtherWindows: "Outras janelas e painéis",
        panelIntro: "Clique no ícone do Vorssaint na barra de menus para abrir o painel. As abas aparecem nesta ordem.",
        panelReorderHint: "Arraste para reordenar. Desligue o que você não precisa.",
        clockTitle: "Relógio da barra de menus",
        clockCaption: "Mostra a data e a hora no lugar do ícone. O ícone volta para atualizações, microfone silenciado ou Keep Awake.",
        clockFormatTitle: "Formato de data e hora",
        clockFormatCaption: "Um padrão de data Unicode. Deixe vazio para usar o formato padrão.",
        clockFormatReset: "Usar padrão",
        clockPreviewLabel: "Prévia",
        clockFormatHelp: "Padrões de formato de data (Unicode TR35)",
        clockSizeTitle: "Tamanho da fonte do relógio",
        clockSizeCaption: "12–16 pt. O padrão, 13 pt, corresponde à barra de menus do sistema.",
        menuBarIconTitle: "Ícone da barra de menus",
        menuBarIconCaption: "Escolha o ícone que o Vorssaint mostra na barra de menus.",
        menuBarIconOther: "Outro símbolo",
        menuBarIconOtherCaption: "Digite o nome de qualquer SF Symbol. Deixe vazio para usar o ícone do Vorssaint.",
        menuBarIconUnknown: "Este Mac não tem um símbolo com esse nome.",
        menuBarIconReset: "Usar o ícone do Vorssaint",
        iconMissingTitle: "Não encontra o ícone?",
        iconMissingCaption: "Uma barra de menus cheia pode escondê-lo, principalmente em Macs com notch.",
        sectionKeepAwake: "Mantém o Mac acordado pelo tempo que você quiser.",
        sectionDisplays: "Brilho das suas telas.",
        sectionMixer: "Volume de cada app, um controle para cada um.",
        sectionSystem: "Processador, gráficos e memória num relance.",
        sectionNetwork: "Velocidade da internet e quais apps estão usando.",
        sectionDisks: "Espaço livre e atividade dos discos.",
        sectionPower: "Bateria, carregamento e consumo de energia.",
        sectionFanControl: "Velocidade das ventoinhas e sua própria curva.",
        sectionUtilities: "Capturas de tela, limpeza, atualizações e outras ferramentas.",
        sectionControls: "Chaves para recursos de mouse, teclado e janelas.",
        sectionToggles: "Ações de um clique, como modo escuro e silenciar o microfone."
    )

    static let tr = GeneralSettingsStrings(
        pageDescription: "Vorssaint’in nasıl başladığı, nasıl göründüğü ve menü çubuğu panelinin neler gösterdiği.",
        appearanceCaption: "Yalnızca Vorssaint’in kendi pencereleri ve panelleri için geçerlidir, tüm Mac için değil.",
        launchAtLoginCaption: "Mac’i her açtığınızda kendiliğinden açılır.",
        liquidGlassCaption: "Cam görünümlü, yarı saydam paneller.",
        liquidGlassOtherWindows: "Diğer pencereler ve paneller",
        panelIntro: "Paneli açmak için menü çubuğundaki Vorssaint simgesine tıklayın. Sekmeler bu sırayla görünür.",
        panelReorderHint: "Sıralamak için sürükleyin. İhtiyaç duymadıklarınızı kapatın.",
        clockTitle: "Menü çubuğu saati",
        clockCaption: "Simge yerine tarih ve saati gösterir. Güncellemelerde, mikrofon sessizken veya Keep Awake sırasında simge geri gelir.",
        clockFormatTitle: "Tarih ve saat biçimi",
        clockFormatCaption: "Bir Unicode tarih deseni. Varsayılan biçimi kullanmak için boş bırakın.",
        clockFormatReset: "Varsayılanı kullan",
        clockPreviewLabel: "Önizleme",
        clockFormatHelp: "Tarih biçimi desenleri (Unicode TR35)",
        clockSizeTitle: "Saat yazı boyutu",
        clockSizeCaption: "12–16 pt. Varsayılan 13 pt, sistem menü çubuğuyla aynıdır.",
        menuBarIconTitle: "Menü çubuğu simgesi",
        menuBarIconCaption: "Vorssaint’in menü çubuğunda gösterdiği simgeyi seçin.",
        menuBarIconOther: "Başka bir sembol",
        menuBarIconOtherCaption: "Herhangi bir SF Symbol adını yazın. Vorssaint simgesini kullanmak için boş bırakın.",
        menuBarIconUnknown: "Bu Mac’te bu adda bir sembol yok.",
        menuBarIconReset: "Vorssaint simgesini kullan",
        iconMissingTitle: "Simgeyi bulamıyor musunuz?",
        iconMissingCaption: "Dolu bir menü çubuğu simgeyi gizleyebilir; özellikle çentikli Mac’lerde.",
        sectionKeepAwake: "Mac’i istediğiniz süre boyunca uyanık tutar.",
        sectionDisplays: "Ekranlarınızın parlaklığı.",
        sectionMixer: "Her uygulamanın sesi, her biri için ayrı bir sürgü.",
        sectionSystem: "İşlemci, grafik ve bellek bir bakışta.",
        sectionNetwork: "İnternet hızı ve hangi uygulamaların kullandığı.",
        sectionDisks: "Boş alan ve disk etkinliği.",
        sectionPower: "Pil, şarj ve güç kullanımı.",
        sectionFanControl: "Fan hızları ve kendi fan eğriniz.",
        sectionUtilities: "Ekran görüntüleri, temizleyici, güncellemeler ve diğer araçlar.",
        sectionControls: "Fare, klavye ve pencere özellikleri için anahtarlar.",
        sectionToggles: "Karanlık mod ve mikrofonu sessize alma gibi tek tıklık eylemler."
    )

    static let ru = GeneralSettingsStrings(
        pageDescription: "Как Vorssaint запускается, как выглядит и что показывает панель в строке меню.",
        appearanceCaption: "Действует только на окна и панели Vorssaint, а не на весь Mac.",
        launchAtLoginCaption: "Открывается сам при каждом включении Mac.",
        liquidGlassCaption: "Полупрозрачные панели, похожие на стекло.",
        liquidGlassOtherWindows: "Другие окна и панели",
        panelIntro: "Нажмите значок Vorssaint в строке меню, чтобы открыть панель. Вкладки идут в этом порядке.",
        panelReorderHint: "Перетаскивайте, чтобы изменить порядок. Выключите то, что вам не нужно.",
        clockTitle: "Часы в строке меню",
        clockCaption: "Показывают дату и время вместо значка. Значок возвращается при обновлениях, выключенном микрофоне или Keep Awake.",
        clockFormatTitle: "Формат даты и времени",
        clockFormatCaption: "Шаблон даты Unicode. Оставьте пустым, чтобы использовать формат по умолчанию.",
        clockFormatReset: "Использовать по умолчанию",
        clockPreviewLabel: "Предпросмотр",
        clockFormatHelp: "Шаблоны формата даты (Unicode TR35)",
        clockSizeTitle: "Размер шрифта часов",
        clockSizeCaption: "12–16 pt. Значение по умолчанию, 13 pt, совпадает со строкой меню системы.",
        menuBarIconTitle: "Значок в строке меню",
        menuBarIconCaption: "Выберите значок, который Vorssaint показывает в строке меню.",
        menuBarIconOther: "Другой символ",
        menuBarIconOtherCaption: "Введите название любого символа SF Symbols. Оставьте поле пустым, чтобы использовать значок Vorssaint.",
        menuBarIconUnknown: "На этом Mac нет символа с таким названием.",
        menuBarIconReset: "Использовать значок Vorssaint",
        iconMissingTitle: "Не находите значок?",
        iconMissingCaption: "Переполненная строка меню может его скрыть, особенно на Mac с вырезом.",
        sectionKeepAwake: "Не даёт Mac уснуть столько, сколько вы захотите.",
        sectionDisplays: "Яркость ваших экранов.",
        sectionMixer: "Громкость каждого приложения, свой ползунок для каждого.",
        sectionSystem: "Процессор, графика и память с одного взгляда.",
        sectionNetwork: "Скорость интернета и какие приложения его используют.",
        sectionDisks: "Свободное место и активность дисков.",
        sectionPower: "Батарея, зарядка и энергопотребление.",
        sectionFanControl: "Скорость вентиляторов и ваша собственная кривая.",
        sectionUtilities: "Снимки экрана, очистка, обновления и другие инструменты.",
        sectionControls: "Переключатели для функций мыши, клавиатуры и окон.",
        sectionToggles: "Действия в одно нажатие, например тёмный режим и отключение микрофона."
    )

    static let es = GeneralSettingsStrings(
        pageDescription: "Cómo se inicia Vorssaint, cómo se ve y qué muestra el panel de la barra de menús.",
        appearanceCaption: "Solo afecta a las ventanas y paneles de Vorssaint, no a todo el Mac.",
        launchAtLoginCaption: "Se abre solo cada vez que enciendes el Mac.",
        liquidGlassCaption: "Paneles translúcidos, con aspecto de cristal.",
        liquidGlassOtherWindows: "Otras ventanas y paneles",
        panelIntro: "Haz clic en el icono de Vorssaint en la barra de menús para abrir el panel. Sus pestañas aparecen en este orden.",
        panelReorderHint: "Arrastra para reordenar. Desactiva lo que no necesites.",
        clockTitle: "Reloj de la barra de menús",
        clockCaption: "Muestra la fecha y la hora en lugar del icono. El icono vuelve para actualizaciones, el micrófono silenciado o Keep Awake.",
        clockFormatTitle: "Formato de fecha y hora",
        clockFormatCaption: "Un patrón de fecha Unicode. Déjalo vacío para usar el formato predeterminado.",
        clockFormatReset: "Usar predeterminado",
        clockPreviewLabel: "Vista previa",
        clockFormatHelp: "Patrones de formato de fecha (Unicode TR35)",
        clockSizeTitle: "Tamaño de letra del reloj",
        clockSizeCaption: "12–16 pt. El valor predeterminado, 13 pt, coincide con la barra de menús del sistema.",
        menuBarIconTitle: "Icono de la barra de menús",
        menuBarIconCaption: "Elige el icono que Vorssaint muestra en la barra de menús.",
        menuBarIconOther: "Otro símbolo",
        menuBarIconOtherCaption: "Escribe el nombre de cualquier SF Symbol. Déjalo vacío para usar el icono de Vorssaint.",
        menuBarIconUnknown: "Este Mac no tiene ningún símbolo con ese nombre.",
        menuBarIconReset: "Usar el icono de Vorssaint",
        iconMissingTitle: "¿No encuentras el icono?",
        iconMissingCaption: "Una barra de menús llena puede ocultarlo, sobre todo en Macs con notch.",
        sectionKeepAwake: "Mantiene el Mac despierto todo el tiempo que quieras.",
        sectionDisplays: "Brillo de tus pantallas.",
        sectionMixer: "Volumen de cada app, con un control para cada una.",
        sectionSystem: "Procesador, gráficos y memoria de un vistazo.",
        sectionNetwork: "Velocidad de internet y qué apps la están usando.",
        sectionDisks: "Espacio libre y actividad de los discos.",
        sectionPower: "Batería, carga y consumo de energía.",
        sectionFanControl: "Velocidad de los ventiladores y tu propia curva.",
        sectionUtilities: "Capturas de pantalla, limpieza, actualizaciones y otras herramientas.",
        sectionControls: "Interruptores para funciones de ratón, teclado y ventanas.",
        sectionToggles: "Acciones de un clic, como el modo oscuro y silenciar el micrófono."
    )

    static let sk = GeneralSettingsStrings(
        pageDescription: "Ako sa Vorssaint spúšťa, ako vyzerá a čo zobrazuje jeho panel v lište.",
        appearanceCaption: "Platí len pre vlastné okná a panely Vorssaint, nie pre celý Mac.",
        launchAtLoginCaption: "Otvorí sa sám vždy, keď zapnete Mac.",
        liquidGlassCaption: "Priehľadné panely v štýle skla.",
        liquidGlassOtherWindows: "Ostatné okná a panely",
        panelIntro: "Kliknutím na ikonu Vorssaint v lište otvoríte panel. Jeho karty sa zobrazujú v tomto poradí.",
        panelReorderHint: "Presunutím zmeníte poradie. Vypnite čokoľvek, čo nepotrebujete.",
        clockTitle: "Hodiny v lište s ponukami",
        clockCaption: "Namiesto ikony zobrazujú dátum a čas. Ikona sa vráti pri aktualizáciách, stlmenom mikrofóne alebo Keep Awake.",
        clockFormatTitle: "Formát dátumu a času",
        clockFormatCaption: "Vzor dátumu Unicode. Ak chcete použiť predvolený formát, nechajte prázdne.",
        clockFormatReset: "Použiť predvolený",
        clockPreviewLabel: "Náhľad",
        clockFormatHelp: "Vzory formátu dátumu (Unicode TR35)",
        clockSizeTitle: "Veľkosť písma hodín",
        clockSizeCaption: "12–16 pt. Predvolených 13 pt zodpovedá systémovej lište s ponukami.",
        menuBarIconTitle: "Ikona v lište s ponukami",
        menuBarIconCaption: "Vyberte ikonu, ktorú Vorssaint zobrazuje v lište s ponukami.",
        menuBarIconOther: "Iný symbol",
        menuBarIconOtherCaption: "Zadajte názov ľubovoľného symbolu SF Symbols. Ak chcete použiť ikonu Vorssaint, nechajte pole prázdne.",
        menuBarIconUnknown: "Tento Mac nemá symbol s týmto názvom.",
        menuBarIconReset: "Použiť ikonu Vorssaint",
        iconMissingTitle: "Nemôžete nájsť ikonu?",
        iconMissingCaption: "Preplnená lišta ju môže skryť, najmä na Macoch s výrezom.",
        sectionKeepAwake: "Udrží váš Mac prebudený tak dlho, ako chcete.",
        sectionDisplays: "Jas vašich obrazoviek.",
        sectionMixer: "Hlasitosť každej aplikácie, každá má vlastný posuvník.",
        sectionSystem: "Procesor, grafika a pamäť na jeden pohľad.",
        sectionNetwork: "Rýchlosť internetu a ktoré aplikácie ho využívajú.",
        sectionDisks: "Voľné miesto a aktivita disku.",
        sectionPower: "Batéria, nabíjanie a spotreba energie.",
        sectionFanControl: "Rýchlosť ventilátorov a vlastná krivka ventilátora.",
        sectionUtilities: "Snímky obrazovky, čistenie, aktualizácie a ďalšie nástroje.",
        sectionControls: "Prepínače pre funkcie myši, klávesnice a okien.",
        sectionToggles: "Akcie na jedno kliknutie, napríklad tmavý režim a stlmenie mikrofónu."
    )

    static let de = GeneralSettingsStrings(
        pageDescription: "Wie Vorssaint startet, wie es aussieht und was das Panel in der Menüleiste zeigt.",
        appearanceCaption: "Gilt nur für die Fenster und Panels von Vorssaint, nicht für den ganzen Mac.",
        launchAtLoginCaption: "Öffnet sich von selbst, sobald du den Mac einschaltest.",
        liquidGlassCaption: "Durchscheinende Panels wie aus Glas.",
        liquidGlassOtherWindows: "Andere Fenster und Panels",
        panelIntro: "Klicke auf das Vorssaint-Symbol in der Menüleiste, um das Panel zu öffnen. Die Tabs erscheinen in dieser Reihenfolge.",
        panelReorderHint: "Zum Umsortieren ziehen. Was du nicht brauchst, einfach ausschalten.",
        clockTitle: "Menüleisten-Uhr",
        clockCaption: "Zeigt Datum und Uhrzeit statt des Symbols. Bei Updates, stummgeschaltetem Mikrofon oder Keep Awake erscheint das Symbol wieder.",
        clockFormatTitle: "Datums- und Zeitformat",
        clockFormatCaption: "Ein Unicode-Datumsmuster. Leer lassen, um das Standardformat zu verwenden.",
        clockFormatReset: "Standard verwenden",
        clockPreviewLabel: "Vorschau",
        clockFormatHelp: "Datumsformat-Muster (Unicode TR35)",
        clockSizeTitle: "Schriftgröße der Uhr",
        clockSizeCaption: "12–16 pt. Die Standardgröße 13 pt entspricht der System-Menüleiste.",
        menuBarIconTitle: "Menüleistensymbol",
        menuBarIconCaption: "Wähle das Symbol, das Vorssaint in der Menüleiste zeigt.",
        menuBarIconOther: "Anderes Symbol",
        menuBarIconOtherCaption: "Gib den Namen eines beliebigen SF Symbols ein. Lass das Feld leer, um das Vorssaint-Symbol zu verwenden.",
        menuBarIconUnknown: "Auf diesem Mac gibt es kein Symbol mit diesem Namen.",
        menuBarIconReset: "Vorssaint-Symbol verwenden",
        iconMissingTitle: "Symbol nicht zu finden?",
        iconMissingCaption: "Eine volle Menüleiste kann es verbergen, vor allem bei Macs mit Notch.",
        sectionKeepAwake: "Hält den Mac so lange wach, wie du willst.",
        sectionDisplays: "Helligkeit deiner Bildschirme.",
        sectionMixer: "Lautstärke jeder App, mit einem eigenen Regler.",
        sectionSystem: "Prozessor, Grafik und Speicher auf einen Blick.",
        sectionNetwork: "Internetgeschwindigkeit und welche Apps sie nutzen.",
        sectionDisks: "Freier Speicherplatz und Festplattenaktivität.",
        sectionPower: "Batterie, Laden und Stromverbrauch.",
        sectionFanControl: "Lüfterdrehzahlen und deine eigene Lüfterkurve.",
        sectionUtilities: "Bildschirmfotos, Bereinigung, Updates und weitere Werkzeuge.",
        sectionControls: "Schalter für Maus-, Tastatur- und Fensterfunktionen.",
        sectionToggles: "Aktionen mit einem Klick, etwa Dunkelmodus und Mikrofon stummschalten."
    )

    static let fr = GeneralSettingsStrings(
        pageDescription: "Comment Vorssaint démarre, à quoi il ressemble et ce que montre le panneau de la barre des menus.",
        appearanceCaption: "Ne concerne que les fenêtres et panneaux de Vorssaint, pas tout le Mac.",
        launchAtLoginCaption: "S’ouvre tout seul à chaque démarrage du Mac.",
        liquidGlassCaption: "Panneaux translucides, à l’aspect de verre.",
        liquidGlassOtherWindows: "Autres fenêtres et panneaux",
        panelIntro: "Cliquez sur l’icône de Vorssaint dans la barre des menus pour ouvrir le panneau. Ses onglets apparaissent dans cet ordre.",
        panelReorderHint: "Glissez pour réordonner. Désactivez ce dont vous n’avez pas besoin.",
        clockTitle: "Horloge de la barre des menus",
        clockCaption: "Affiche la date et l’heure à la place de l’icône. L’icône revient pour les mises à jour, le micro coupé ou Keep Awake.",
        clockFormatTitle: "Format de date et d’heure",
        clockFormatCaption: "Un modèle de date Unicode. Laissez vide pour utiliser le format par défaut.",
        clockFormatReset: "Utiliser le format par défaut",
        clockPreviewLabel: "Aperçu",
        clockFormatHelp: "Modèles de format de date (Unicode TR35)",
        clockSizeTitle: "Taille de police de l’horloge",
        clockSizeCaption: "12 à 16 pt. La valeur par défaut, 13 pt, correspond à la barre des menus du système.",
        menuBarIconTitle: "Icône de la barre des menus",
        menuBarIconCaption: "Choisissez l’icône que Vorssaint affiche dans la barre des menus.",
        menuBarIconOther: "Autre symbole",
        menuBarIconOtherCaption: "Saisissez le nom de n’importe quel SF Symbol. Laissez vide pour utiliser l’icône de Vorssaint.",
        menuBarIconUnknown: "Ce Mac n’a aucun symbole portant ce nom.",
        menuBarIconReset: "Utiliser l’icône de Vorssaint",
        iconMissingTitle: "Vous ne trouvez pas l’icône\u{00A0}?",
        iconMissingCaption: "Une barre des menus encombrée peut la masquer, surtout sur les Mac avec encoche.",
        sectionKeepAwake: "Garde le Mac éveillé aussi longtemps que vous voulez.",
        sectionDisplays: "Luminosité de vos écrans.",
        sectionMixer: "Volume de chaque app, avec un curseur pour chacune.",
        sectionSystem: "Processeur, graphismes et mémoire en un coup d’œil.",
        sectionNetwork: "Vitesse d’Internet et apps qui l’utilisent.",
        sectionDisks: "Espace libre et activité des disques.",
        sectionPower: "Batterie, charge et consommation d’énergie.",
        sectionFanControl: "Vitesse des ventilateurs et votre propre courbe.",
        sectionUtilities: "Captures d’écran, nettoyage, mises à jour et autres outils.",
        sectionControls: "Interrupteurs pour les fonctions de souris, clavier et fenêtres.",
        sectionToggles: "Actions en un clic, comme le mode sombre et la coupure du micro."
    )

    static let it = GeneralSettingsStrings(
        pageDescription: "Come si avvia Vorssaint, che aspetto ha e cosa mostra il pannello nella barra dei menu.",
        appearanceCaption: "Vale solo per le finestre e i pannelli di Vorssaint, non per tutto il Mac.",
        launchAtLoginCaption: "Si apre da solo ogni volta che accendi il Mac.",
        liquidGlassCaption: "Pannelli traslucidi, con l’aspetto del vetro.",
        liquidGlassOtherWindows: "Altre finestre e pannelli",
        panelIntro: "Fai clic sull’icona di Vorssaint nella barra dei menu per aprire il pannello. Le sue schede compaiono in questo ordine.",
        panelReorderHint: "Trascina per riordinare. Disattiva ciò che non ti serve.",
        clockTitle: "Orologio nella barra dei menu",
        clockCaption: "Mostra data e ora al posto dell’icona. L’icona torna per aggiornamenti, microfono silenziato o Keep Awake.",
        clockFormatTitle: "Formato di data e ora",
        clockFormatCaption: "Un modello di data Unicode. Lascia vuoto per usare il formato predefinito.",
        clockFormatReset: "Usa predefinito",
        clockPreviewLabel: "Anteprima",
        clockFormatHelp: "Modelli di formato data (Unicode TR35)",
        clockSizeTitle: "Dimensione carattere orologio",
        clockSizeCaption: "12–16 pt. Il valore predefinito, 13 pt, corrisponde alla barra dei menu di sistema.",
        menuBarIconTitle: "Icona della barra dei menu",
        menuBarIconCaption: "Scegli l’icona che Vorssaint mostra nella barra dei menu.",
        menuBarIconOther: "Altro simbolo",
        menuBarIconOtherCaption: "Digita il nome di un qualsiasi SF Symbol. Lascia vuoto per usare l’icona di Vorssaint.",
        menuBarIconUnknown: "Questo Mac non ha nessun simbolo con questo nome.",
        menuBarIconReset: "Usa l’icona di Vorssaint",
        iconMissingTitle: "Non trovi l’icona?",
        iconMissingCaption: "Una barra dei menu affollata può nasconderla, soprattutto sui Mac con notch.",
        sectionKeepAwake: "Tiene il Mac sveglio per tutto il tempo che vuoi.",
        sectionDisplays: "Luminosità dei tuoi schermi.",
        sectionMixer: "Volume di ogni app, con un cursore per ciascuna.",
        sectionSystem: "Processore, grafica e memoria a colpo d’occhio.",
        sectionNetwork: "Velocità di Internet e quali app la stanno usando.",
        sectionDisks: "Spazio libero e attività dei dischi.",
        sectionPower: "Batteria, ricarica e consumo di energia.",
        sectionFanControl: "Velocità delle ventole e la tua curva personale.",
        sectionUtilities: "Istantanee, pulizia, aggiornamenti e altri strumenti.",
        sectionControls: "Interruttori per le funzioni di mouse, tastiera e finestre.",
        sectionToggles: "Azioni con un clic, come la modalità scura e il silenziamento del microfono."
    )

    static let ja = GeneralSettingsStrings(
        pageDescription: "Vorssaint の起動方法、外観、メニューバーのパネルに表示する内容。",
        appearanceCaption: "Vorssaint のウインドウとパネルにだけ適用され、Mac 全体には影響しません。",
        launchAtLoginCaption: "Mac の電源を入れるたびに自動で開きます。",
        liquidGlassCaption: "ガラスのように透ける半透明のパネル。",
        liquidGlassOtherWindows: "ほかのウインドウとパネル",
        panelIntro: "メニューバーの Vorssaint アイコンをクリックするとパネルが開きます。タブはこの順番で表示されます。",
        panelReorderHint: "ドラッグして並べ替え。不要なものはオフにします。",
        clockTitle: "メニューバーの時計",
        clockCaption: "アイコンの代わりに日付と時刻を表示します。アップデート、マイクのミュート、Keep Awake のときはアイコンが戻ります。",
        clockFormatTitle: "日付と時刻の形式",
        clockFormatCaption: "Unicode の日付パターン。空欄にすると既定の形式を使います。",
        clockFormatReset: "既定に戻す",
        clockPreviewLabel: "プレビュー",
        clockFormatHelp: "日付書式の説明（Unicode TR35）",
        clockSizeTitle: "時計の文字サイズ",
        clockSizeCaption: "12〜16 pt。既定の 13 pt はシステムのメニューバーと同じです。",
        menuBarIconTitle: "メニューバーのアイコン",
        menuBarIconCaption: "Vorssaint がメニューバーに表示するアイコンを選びます。",
        menuBarIconOther: "ほかのシンボル",
        menuBarIconOtherCaption: "SF Symbols のシンボル名を入力します。空欄にすると Vorssaint のアイコンを使います。",
        menuBarIconUnknown: "この Mac にはその名前のシンボルがありません。",
        menuBarIconReset: "Vorssaint のアイコンを使用",
        iconMissingTitle: "アイコンが見つからない場合",
        iconMissingCaption: "メニューバーがいっぱいだと隠れることがあります。ノッチのある Mac では特によく起こります。",
        sectionKeepAwake: "好きな時間だけ Mac をスリープさせません。",
        sectionDisplays: "ディスプレイの明るさ。",
        sectionMixer: "アプリごとの音量。それぞれにスライダーがあります。",
        sectionSystem: "プロセッサ、グラフィックス、メモリをひと目で。",
        sectionNetwork: "インターネットの速度と、それを使っているアプリ。",
        sectionDisks: "空き容量とディスクのアクティビティ。",
        sectionPower: "バッテリー、充電、消費電力。",
        sectionFanControl: "ファンの回転数と自分で決めるファンカーブ。",
        sectionUtilities: "スクリーンショット、クリーナー、アップデートなどのツール。",
        sectionControls: "マウス、キーボード、ウインドウ機能のスイッチ。",
        sectionToggles: "ダークモードやマイクのミュートなど、ワンクリックの操作。"
    )

    static let ko = GeneralSettingsStrings(
        pageDescription: "Vorssaint가 시작되는 방식, 모습, 그리고 메뉴 막대 패널에 표시되는 내용.",
        appearanceCaption: "Vorssaint의 윈도우와 패널에만 적용되며 Mac 전체에는 영향을 주지 않습니다.",
        launchAtLoginCaption: "Mac을 켤 때마다 자동으로 열립니다.",
        liquidGlassCaption: "유리처럼 비치는 반투명 패널.",
        liquidGlassOtherWindows: "다른 윈도우와 패널",
        panelIntro: "메뉴 막대의 Vorssaint 아이콘을 클릭하면 패널이 열립니다. 탭은 이 순서로 표시됩니다.",
        panelReorderHint: "드래그하여 순서를 바꾸고, 필요 없는 것은 끄세요.",
        clockTitle: "메뉴 막대 시계",
        clockCaption: "아이콘 대신 날짜와 시간을 표시합니다. 업데이트, 마이크 음소거, Keep Awake 중에는 아이콘이 다시 나타납니다.",
        clockFormatTitle: "날짜 및 시간 형식",
        clockFormatCaption: "Unicode 날짜 패턴입니다. 비워 두면 기본 형식을 사용합니다.",
        clockFormatReset: "기본값 사용",
        clockPreviewLabel: "미리보기",
        clockFormatHelp: "날짜 형식 설명(Unicode TR35)",
        clockSizeTitle: "시계 글자 크기",
        clockSizeCaption: "12–16 pt. 기본값 13 pt는 시스템 메뉴 막대와 같습니다.",
        menuBarIconTitle: "메뉴 막대 아이콘",
        menuBarIconCaption: "Vorssaint가 메뉴 막대에 표시할 아이콘을 선택하세요.",
        menuBarIconOther: "다른 심볼",
        menuBarIconOtherCaption: "SF Symbols의 심볼 이름을 입력하세요. 비워 두면 Vorssaint 아이콘을 사용합니다.",
        menuBarIconUnknown: "이 Mac에는 해당 이름의 심볼이 없습니다.",
        menuBarIconReset: "Vorssaint 아이콘 사용",
        iconMissingTitle: "아이콘이 보이지 않나요?",
        iconMissingCaption: "메뉴 막대가 가득 차면 숨겨질 수 있습니다. 노치가 있는 Mac에서 특히 흔합니다.",
        sectionKeepAwake: "원하는 시간만큼 Mac을 깨어 있게 합니다.",
        sectionDisplays: "화면의 밝기.",
        sectionMixer: "앱별 음량, 각각 슬라이더로 조절.",
        sectionSystem: "프로세서, 그래픽, 메모리를 한눈에.",
        sectionNetwork: "인터넷 속도와 이를 사용하는 앱.",
        sectionDisks: "남은 공간과 디스크 활동.",
        sectionPower: "배터리, 충전, 전력 사용량.",
        sectionFanControl: "팬 속도와 직접 만드는 팬 곡선.",
        sectionUtilities: "스크린샷, 클리너, 업데이트 및 기타 도구.",
        sectionControls: "마우스, 키보드, 윈도우 기능 스위치.",
        sectionToggles: "다크 모드, 마이크 음소거 같은 원클릭 동작."
    )

    static let zhHans = GeneralSettingsStrings(
        pageDescription: "Vorssaint 的启动方式、外观，以及菜单栏面板显示的内容。",
        appearanceCaption: "仅影响 Vorssaint 自己的窗口和面板，不影响整台 Mac。",
        launchAtLoginCaption: "每次开机时自动打开。",
        liquidGlassCaption: "像玻璃一样通透的半透明面板。",
        liquidGlassOtherWindows: "其他窗口和面板",
        panelIntro: "点按菜单栏中的 Vorssaint 图标即可打开面板。标签页按此顺序显示。",
        panelReorderHint: "拖动可重新排序。不需要的关掉即可。",
        clockTitle: "菜单栏时钟",
        clockCaption: "用日期和时间代替图标。更新、麦克风静音或 Keep Awake 时仍会显示图标。",
        clockFormatTitle: "日期时间格式",
        clockFormatCaption: "Unicode 日期格式。留空则使用默认格式。",
        clockFormatReset: "恢复默认",
        clockPreviewLabel: "预览",
        clockFormatHelp: "标准日期格式说明（Unicode TR35）",
        clockSizeTitle: "时钟字号",
        clockSizeCaption: "12–16 pt。默认 13 pt，与系统菜单栏一致。",
        menuBarIconTitle: "菜单栏图标",
        menuBarIconCaption: "选择 Vorssaint 在菜单栏中显示的图标。",
        menuBarIconOther: "其他符号",
        menuBarIconOtherCaption: "输入任意 SF Symbol 的名称。留空则使用 Vorssaint 图标。",
        menuBarIconUnknown: "此 Mac 上没有该名称的符号。",
        menuBarIconReset: "使用 Vorssaint 图标",
        iconMissingTitle: "找不到图标？",
        iconMissingCaption: "菜单栏太满时图标可能被隐藏，带刘海的 Mac 上尤其常见。",
        sectionKeepAwake: "让 Mac 在你需要的时间内保持唤醒。",
        sectionDisplays: "显示器亮度。",
        sectionMixer: "每个 App 的音量，各有一个滑块。",
        sectionSystem: "处理器、图形和内存一目了然。",
        sectionNetwork: "网速以及正在使用网络的 App。",
        sectionDisks: "可用空间和磁盘活动。",
        sectionPower: "电池、充电和功耗。",
        sectionFanControl: "风扇转速和你自己的风扇曲线。",
        sectionUtilities: "截屏、清理、更新和其他工具。",
        sectionControls: "鼠标、键盘和窗口功能的开关。",
        sectionToggles: "深色模式、静音麦克风等一键操作。"
    )

    static let zhTW = GeneralSettingsStrings(
        pageDescription: "Vorssaint 的啟動方式、外觀，以及選單列面板顯示的內容。",
        appearanceCaption: "僅影響 Vorssaint 自己的視窗和面板，不影響整台 Mac。",
        launchAtLoginCaption: "每次開機時自動開啟。",
        liquidGlassCaption: "像玻璃一樣通透的半透明面板。",
        liquidGlassOtherWindows: "其他視窗和面板",
        panelIntro: "按一下選單列中的 Vorssaint 圖示即可開啟面板。標籤頁會依此順序顯示。",
        panelReorderHint: "拖曳可重新排序。不需要的關掉即可。",
        clockTitle: "選單列時鐘",
        clockCaption: "以日期和時間取代圖示。更新、麥克風靜音或 Keep Awake 時仍會顯示圖示。",
        clockFormatTitle: "日期時間格式",
        clockFormatCaption: "Unicode 日期格式。留空則使用預設格式。",
        clockFormatReset: "恢復預設",
        clockPreviewLabel: "預覽",
        clockFormatHelp: "標準日期格式說明（Unicode TR35）",
        clockSizeTitle: "時鐘字級",
        clockSizeCaption: "12–16 pt。預設 13 pt，與系統選單列一致。",
        menuBarIconTitle: "選單列圖示",
        menuBarIconCaption: "選擇 Vorssaint 在選單列中顯示的圖示。",
        menuBarIconOther: "其他符號",
        menuBarIconOtherCaption: "輸入任一 SF Symbol 的名稱。留空則使用 Vorssaint 圖示。",
        menuBarIconUnknown: "此 Mac 上沒有該名稱的符號。",
        menuBarIconReset: "使用 Vorssaint 圖示",
        iconMissingTitle: "找不到圖示？",
        iconMissingCaption: "選單列太滿時圖示可能被隱藏，有瀏海的 Mac 上尤其常見。",
        sectionKeepAwake: "讓 Mac 在你需要的時間內保持喚醒。",
        sectionDisplays: "顯示器亮度。",
        sectionMixer: "每個 App 的音量，各有一個滑桿。",
        sectionSystem: "處理器、圖形和記憶體一目了然。",
        sectionNetwork: "網路速度以及正在使用網路的 App。",
        sectionDisks: "可用空間和磁碟活動。",
        sectionPower: "電池、充電和耗電。",
        sectionFanControl: "風扇轉速和你自訂的風扇曲線。",
        sectionUtilities: "截圖、清理、更新和其他工具。",
        sectionControls: "滑鼠、鍵盤和視窗功能的開關。",
        sectionToggles: "深色模式、將麥克風靜音等一鍵操作。"
    )

    static let zhHK = GeneralSettingsStrings(
        pageDescription: "Vorssaint 的啟動方式、外觀，以及選單列面板顯示的內容。",
        appearanceCaption: "只影響 Vorssaint 自己的視窗和面板，不影響整部 Mac。",
        launchAtLoginCaption: "每次開機時自動開啟。",
        liquidGlassCaption: "像玻璃一樣通透的半透明面板。",
        liquidGlassOtherWindows: "其他視窗和面板",
        panelIntro: "按一下選單列中的 Vorssaint 圖示即可開啟面板。分頁會按此次序顯示。",
        panelReorderHint: "拖曳可重新排序。不需要的關掉即可。",
        clockTitle: "選單列時鐘",
        clockCaption: "以日期和時間取代圖示。更新、麥克風靜音或 Keep Awake 時仍會顯示圖示。",
        clockFormatTitle: "日期時間格式",
        clockFormatCaption: "Unicode 日期格式。留空則使用預設格式。",
        clockFormatReset: "回復預設",
        clockPreviewLabel: "預覽",
        clockFormatHelp: "標準日期格式說明（Unicode TR35）",
        clockSizeTitle: "時鐘字級",
        clockSizeCaption: "12–16 pt。預設 13 pt，與系統選單列一致。",
        menuBarIconTitle: "選單列圖示",
        menuBarIconCaption: "選擇 Vorssaint 在選單列中顯示的圖示。",
        menuBarIconOther: "其他符號",
        menuBarIconOtherCaption: "輸入任何 SF Symbol 的名稱。留空則使用 Vorssaint 圖示。",
        menuBarIconUnknown: "此 Mac 上沒有該名稱的符號。",
        menuBarIconReset: "使用 Vorssaint 圖示",
        iconMissingTitle: "找不到圖示？",
        iconMissingCaption: "選單列太滿時圖示可能被隱藏，有瀏海的 Mac 上尤其常見。",
        sectionKeepAwake: "讓 Mac 在你需要的時間內保持喚醒。",
        sectionDisplays: "顯示器亮度。",
        sectionMixer: "每個 App 的音量，各有一個滑桿。",
        sectionSystem: "處理器、圖像和記憶體一目了然。",
        sectionNetwork: "網絡速度以及正在使用網絡的 App。",
        sectionDisks: "可用空間和磁碟活動。",
        sectionPower: "電池、充電和耗電。",
        sectionFanControl: "風扇轉速和你自訂的風扇曲線。",
        sectionUtilities: "截圖、清理、更新和其他工具。",
        sectionControls: "滑鼠、鍵盤和視窗功能的開關。",
        sectionToggles: "深色模式、將麥克風靜音等一鍵操作。"
    )
}
