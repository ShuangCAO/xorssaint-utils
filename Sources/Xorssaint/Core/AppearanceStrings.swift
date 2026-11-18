// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

struct AppearanceStrings {
    let label: String
    let system: String
    let light: String
    let dark: String
    let liquidGlass: String
    let editorLabel: String
    let editorCaption: String
    let editorFollowApp: String
}

extension FeatureStrings {
    static func appearance(_ language: AppLanguage) -> AppearanceStrings {
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

extension AppearanceStrings {
    static let enUS = AppearanceStrings(
        label: "Appearance",
        system: "System",
        light: "Light",
        dark: "Dark",
        liquidGlass: "Liquid Glass",
        editorLabel: "Editor appearance",
        editorCaption: "The editor’s colours. Following the app keeps it the same as the rest of Xorssaint.",
        editorFollowApp: "Follow the app"
    )

    static let ptBR = AppearanceStrings(
        label: "Aparência",
        system: "Sistema",
        light: "Clara",
        dark: "Escura",
        liquidGlass: "Liquid Glass",
        editorLabel: "Aparência do editor",
        editorCaption: "As cores do editor. Seguir o app mantém igual ao resto do Xorssaint.",
        editorFollowApp: "Seguir o app"
    )

    static let tr = AppearanceStrings(
        label: "Görünüm",
        system: "Sistem",
        light: "Açık",
        dark: "Koyu",
        liquidGlass: "Liquid Glass",
        editorLabel: "Düzenleyici görünümü",
        editorCaption: "Düzenleyicinin renkleri. Uygulamayı izlemek onu Xorssaint’in geri kalanıyla aynı tutar.",
        editorFollowApp: "Uygulamayı izle"
    )

    static let ru = AppearanceStrings(
        label: "Оформление",
        system: "Системное",
        light: "Светлое",
        dark: "Тёмное",
        liquidGlass: "Liquid Glass",
        editorLabel: "Оформление редактора",
        editorCaption: "Цвета редактора. Следование за приложением сохраняет его как у остального Xorssaint.",
        editorFollowApp: "Как в приложении"
    )

    static let es = AppearanceStrings(
        label: "Apariencia",
        system: "Sistema",
        light: "Clara",
        dark: "Oscura",
        liquidGlass: "Liquid Glass",
        editorLabel: "Apariencia del editor",
        editorCaption: "Los colores del editor. Seguir la aplicación lo mantiene como el resto de Xorssaint.",
        editorFollowApp: "Seguir la aplicación"
    )

    static let sk = AppearanceStrings(
        label: "Vzhľad",
        system: "Systémový",
        light: "Svetlý",
        dark: "Tmavý",
        liquidGlass: "Liquid Glass",
        editorLabel: "Vzhľad editora",
        editorCaption: "Farby editora. Sledovanie aplikácie ho udržiava rovnaké ako zvyšok Xorssaint.",
        editorFollowApp: "Sledovať aplikáciu"
    )

    static let de = AppearanceStrings(
        label: "Erscheinungsbild",
        system: "System",
        light: "Hell",
        dark: "Dunkel",
        liquidGlass: "Liquid Glass",
        editorLabel: "Erscheinungsbild des Editors",
        editorCaption: "Die Farben des Editors. „App folgen“ hält ihn wie den Rest von Xorssaint.",
        editorFollowApp: "App folgen"
    )

    static let fr = AppearanceStrings(
        label: "Apparence",
        system: "Système",
        light: "Clair",
        dark: "Sombre",
        liquidGlass: "Liquid Glass",
        editorLabel: "Apparence de l’éditeur",
        editorCaption: "Les couleurs de l’éditeur. Suivre l’application le garde comme le reste de Xorssaint.",
        editorFollowApp: "Suivre l’application"
    )

    static let it = AppearanceStrings(
        label: "Aspetto",
        system: "Sistema",
        light: "Chiaro",
        dark: "Scuro",
        liquidGlass: "Liquid Glass",
        editorLabel: "Aspetto dell’editor",
        editorCaption: "I colori dell’editor. Seguire l’app lo mantiene come il resto di Xorssaint.",
        editorFollowApp: "Segui l’app"
    )

    static let ja = AppearanceStrings(
        label: "外観",
        system: "システム",
        light: "ライト",
        dark: "ダーク",
        liquidGlass: "Liquid Glass",
        editorLabel: "エディターの外観",
        editorCaption: "エディターの配色。「アプリに従う」を選ぶと Xorssaint の他の部分と同じ表示になります。",
        editorFollowApp: "アプリに従う"
    )

    static let ko = AppearanceStrings(
        label: "외관",
        system: "시스템",
        light: "밝게",
        dark: "어둡게",
        liquidGlass: "Liquid Glass",
        editorLabel: "편집기 외관",
        editorCaption: "편집기의 색상입니다. 앱을 따름을 선택하면 Xorssaint의 나머지 부분과 똑같이 표시됩니다.",
        editorFollowApp: "앱을 따름"
    )

    static let zhHans = AppearanceStrings(
        label: "外观",
        system: "跟随系统",
        light: "浅色",
        dark: "深色",
        liquidGlass: "Liquid Glass",
        editorLabel: "编辑器外观",
        editorCaption: "截图编辑器的配色。选择「跟随应用」时与 Xorssaint 的其余部分保持一致。",
        editorFollowApp: "跟随应用"
    )

    static let zhTW = AppearanceStrings(
        label: "外觀",
        system: "跟隨系統",
        light: "淺色",
        dark: "深色",
        liquidGlass: "Liquid Glass",
        editorLabel: "編輯器外觀",
        editorCaption: "截圖編輯器的配色。選擇「跟隨應用」時與 Xorssaint 的其餘部分保持一致。",
        editorFollowApp: "跟隨應用"
    )

    static let zhHK = AppearanceStrings(
        label: "外觀",
        system: "跟隨系統",
        light: "淺色",
        dark: "深色",
        liquidGlass: "Liquid Glass",
        editorLabel: "編輯器外觀",
        editorCaption: "截圖編輯器的配色。選擇「跟隨應用」時與 Xorssaint 的其餘部分保持一致。",
        editorFollowApp: "跟隨應用"
    )
    static let uk = AppearanceStrings(
        label: "Вигляд",
        system: "Система",
        light: "Світлий",
        dark: "Темний",
        liquidGlass: "Liquid Glass",
        editorLabel: "Вигляд редактора",
        editorCaption: "Кольори редактора. «Як у застосунку» тримає його таким самим, як решта Xorssaint.",
        editorFollowApp: "Як у застосунку"
    )
}
