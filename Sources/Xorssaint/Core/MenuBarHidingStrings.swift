// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

struct MenuBarHidingStrings {
    let title: String
    let pageDescription: String
    let limitationsTitle: String
    let limitationApps: String
    let limitationSystem: String
    let unavailableOS: String
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
        pageDescription: "Choose which apps’ menu bar icons stay hidden on macOS 27.",
        limitationsTitle: "Notes",
        limitationApps: "Hiding works per app: an app with several icons hides and returns as a group.",
        limitationSystem: "System items (clock, Wi-Fi, Control Center) always stay visible.",
        unavailableOS: "Requires macOS 27 or newer"
    )

    static let zhHans = MenuBarHidingStrings(
        title: "菜单栏图标隐藏",
        pageDescription: "在 macOS 27 上选择哪些 App 的菜单栏图标保持隐藏。",
        limitationsTitle: "说明",
        limitationApps: "隐藏以 App 为单位：一个 App 有多个图标时一起隐藏、一起恢复。",
        limitationSystem: "系统项（时钟、Wi-Fi、控制中心）始终显示。",
        unavailableOS: "需要 macOS 27 或更新版本"
    )

    static let zhTW = MenuBarHidingStrings(
        title: "選單列圖示隱藏",
        pageDescription: "在 macOS 27 上選擇哪些 App 的選單列圖示保持隱藏。",
        limitationsTitle: "說明",
        limitationApps: "隱藏以 App 為單位：一個 App 有多個圖示時會一起隱藏、一起恢復。",
        limitationSystem: "系統項目（時鐘、Wi-Fi、控制中心）一律顯示。",
        unavailableOS: "需要 macOS 27 或更新版本"
    )

    static let zhHK = MenuBarHidingStrings(
        title: "選單列圖示隱藏",
        pageDescription: "喺 macOS 27 上揀選邊啲 App 嘅選單列圖示保持隱藏。",
        limitationsTitle: "說明",
        limitationApps: "隱藏以 App 為單位：一個 App 有多個圖示時會一齊隱藏、一齊恢復。",
        limitationSystem: "系統項目（時鐘、Wi-Fi、控制中心）一律顯示。",
        unavailableOS: "需要 macOS 27 或更新版本"
    )

    static let ja = MenuBarHidingStrings(
        title: "メニューバーアイコンを隠す",
        pageDescription: "macOS 27 で隠したい App のメニューバーアイコンを選びます。",
        limitationsTitle: "注意",
        limitationApps: "非表示は App 単位です。複数のアイコンを持つ App はまとめて隠れ、まとめて戻ります。",
        limitationSystem: "システム項目（時計、Wi-Fi、コントロールセンター）は常に表示されます。",
        unavailableOS: "macOS 27 以降が必要です"
    )

    static let ko = MenuBarHidingStrings(
        title: "메뉴 막대 아이콘 숨기기",
        pageDescription: "macOS 27에서 숨길 App의 메뉴 막대 아이콘을 선택합니다.",
        limitationsTitle: "참고",
        limitationApps: "숨기기는 App 단위입니다. 아이콘이 여러 개인 App은 함께 숨겨지고 함께 돌아옵니다.",
        limitationSystem: "시스템 항목(시계, Wi-Fi, 제어 센터)은 항상 표시됩니다.",
        unavailableOS: "macOS 27 이상이 필요합니다"
    )

    static let de = MenuBarHidingStrings(
        title: "Menüleisten-Symbole ausblenden",
        pageDescription: "Wähle auf macOS 27, welche App-Symbole in der Menüleiste verborgen bleiben.",
        limitationsTitle: "Hinweise",
        limitationApps: "Das Ausblenden gilt je App: Eine App mit mehreren Symbolen verschwindet und kehrt als Gruppe zurück.",
        limitationSystem: "Systemelemente (Uhr, WLAN, Kontrollzentrum) bleiben immer sichtbar.",
        unavailableOS: "Erfordert macOS 27 oder neuer"
    )

    static let fr = MenuBarHidingStrings(
        title: "Masquer les icônes de la barre de menus",
        pageDescription: "Choisis sur macOS 27 quelles icônes de barre de menus restent masquées.",
        limitationsTitle: "Remarques",
        limitationApps: "Le masquage se fait par app : une app à plusieurs icônes disparaît et revient en groupe.",
        limitationSystem: "Les éléments système (horloge, Wi-Fi, centre de contrôle) restent toujours visibles.",
        unavailableOS: "Nécessite macOS 27 ou ultérieur"
    )

    static let es = MenuBarHidingStrings(
        title: "Ocultar iconos de la barra de menús",
        pageDescription: "Elige en macOS 27 qué iconos de la barra de menús permanecen ocultos.",
        limitationsTitle: "Notas",
        limitationApps: "El ocultado va por app: una app con varios iconos se oculta y vuelve en grupo.",
        limitationSystem: "Los elementos del sistema (reloj, Wi-Fi, Centro de Control) siempre permanecen visibles.",
        unavailableOS: "Requiere macOS 27 o posterior"
    )

    static let it = MenuBarHidingStrings(
        title: "Nascondi le icone della barra dei menu",
        pageDescription: "Scegli su macOS 27 quali icone della barra dei menu restano nascoste.",
        limitationsTitle: "Note",
        limitationApps: "La nascita vale per app: un’app con più icone sparisce e torna in gruppo.",
        limitationSystem: "Gli elementi di sistema (orologio, Wi-Fi, Centro di Controllo) restano sempre visibili.",
        unavailableOS: "Richiede macOS 27 o successivo"
    )

    static let ptBR = MenuBarHidingStrings(
        title: "Ocultar ícones da barra de menus",
        pageDescription: "Escolha no macOS 27 quais ícones da barra de menus ficam ocultos.",
        limitationsTitle: "Observações",
        limitationApps: "A ocultação vale por app: um app com vários ícones some e volta em grupo.",
        limitationSystem: "Itens do sistema (relógio, Wi-Fi, Central de Controle) ficam sempre visíveis.",
        unavailableOS: "Requer macOS 27 ou posterior"
    )

    static let tr = MenuBarHidingStrings(
        title: "Menü çubuğu simgelerini gizle",
        pageDescription: "macOS 27’de hangi uygulamaların menü çubuğu simgelerinin gizli kalacağını seç.",
        limitationsTitle: "Notlar",
        limitationApps: "Gizleme uygulama başınadır: birkaç simgesi olan uygulama topluca gizlenir ve döner.",
        limitationSystem: "Sistem öğeleri (saat, Wi-Fi, Denetim Merkezi) her zaman görünür kalır.",
        unavailableOS: "macOS 27 veya üstü gerekir"
    )

    static let ru = MenuBarHidingStrings(
        title: "Скрытие значков в строке меню",
        pageDescription: "Выберите в macOS 27, у каких приложений значки в строке меню останутся скрытыми.",
        limitationsTitle: "Примечания",
        limitationApps: "Скрытие идёт по приложению: приложение с несколькими значками скрывается и возвращается целиком.",
        limitationSystem: "Системные элементы (часы, Wi-Fi, Пункт управления) всегда остаются видимыми.",
        unavailableOS: "Требуется macOS 27 или новее"
    )

    static let uk = MenuBarHidingStrings(
        title: "Приховування значків у рядку меню",
        pageDescription: "Оберіть у macOS 27, у яких програм значки в рядку меню лишатимуться прихованими.",
        limitationsTitle: "Примітки",
        limitationApps: "Приховування діє на програму: програма з кількома значками ховається і повертається разом.",
        limitationSystem: "Системні елементи (годинник, Wi-Fi, Пункт керування) завжди видимі.",
        unavailableOS: "Потрібен macOS 27 або новіший"
    )

    static let sk = MenuBarHidingStrings(
        title: "Skrytie ikon v lište menu",
        pageDescription: "Vyber na macOS 27, ktorých ikony v lište menu zostanú skryté.",
        limitationsTitle: "Poznámky",
        limitationApps: "Skrývanie platí podľa aplikácie: aplikácia s viacerými ikonami sa skryje a vráti ako celok.",
        limitationSystem: "Systémové položky (hodiny, Wi-Fi, Ovládacie centrum) sú vždy viditeľné.",
        unavailableOS: "Vyžaduje macOS 27 alebo novší"
    )
}
