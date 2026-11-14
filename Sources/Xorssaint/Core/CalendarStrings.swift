// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// Copy for the panel's month calendar. Month and weekday names come from
/// the calendar itself; these are the few labels the panel owns.
struct CalendarPanelStrings {
    let title: String
    let today: String
    let previousMonth: String
    let nextMonth: String
    let weekStartTitle: String
    let weekStartCaption: String
    let panelDescription: String
}

extension FeatureStrings {
    static func calendarPanel(_ language: AppLanguage) -> CalendarPanelStrings {
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

extension CalendarPanelStrings {
    static let enUS = CalendarPanelStrings(
        title: "Calendar",
        today: "Today",
        previousMonth: "Previous month",
        nextMonth: "Next month",
        weekStartTitle: "Start weeks on Monday",
        weekStartCaption: "Turn off to start on Sunday.",
        panelDescription: "Months, weekdays and today."
    )

    static let zhHans = CalendarPanelStrings(
        title: "日历",
        today: "今天",
        previousMonth: "上个月",
        nextMonth: "下个月",
        weekStartTitle: "周一作为一周的第一天",
        weekStartCaption: "关闭则从周日开始。",
        panelDescription: "月份、星期与今天。"
    )

    static let zhTW = CalendarPanelStrings(
        title: "日曆",
        today: "今天",
        previousMonth: "上個月",
        nextMonth: "下個月",
        weekStartTitle: "週一作為一週的第一天",
        weekStartCaption: "關閉則從週日開始。",
        panelDescription: "月份、星期與今天。"
    )

    static let zhHK = CalendarPanelStrings(
        title: "日曆",
        today: "今天",
        previousMonth: "上個月",
        nextMonth: "下個月",
        weekStartTitle: "週一作為一週的第一天",
        weekStartCaption: "關閉則從週日開始。",
        panelDescription: "月份、星期與今天。"
    )

    static let ja = CalendarPanelStrings(
        title: "カレンダー",
        today: "今日",
        previousMonth: "前の月",
        nextMonth: "次の月",
        weekStartTitle: "週の始まりを月曜日に",
        weekStartCaption: "オフにすると日曜日から始まります。",
        panelDescription: "月・曜日・今日。"
    )

    static let ko = CalendarPanelStrings(
        title: "달력",
        today: "오늘",
        previousMonth: "이전 달",
        nextMonth: "다음 달",
        weekStartTitle: "주를 월요일부터 시작",
        weekStartCaption: "끄면 일요일부터 시작합니다.",
        panelDescription: "월, 요일, 오늘."
    )

    static let de = CalendarPanelStrings(
        title: "Kalender",
        today: "Heute",
        previousMonth: "Vorheriger Monat",
        nextMonth: "Nächster Monat",
        weekStartTitle: "Wochen beginnen am Montag",
        weekStartCaption: "Ausschalten, um am Sonntag zu beginnen.",
        panelDescription: "Monate, Wochentage und heute."
    )

    static let fr = CalendarPanelStrings(
        title: "Calendrier",
        today: "Aujourd’hui",
        previousMonth: "Mois précédent",
        nextMonth: "Mois suivant",
        weekStartTitle: "La semaine commence le lundi",
        weekStartCaption: "Désactivez pour commencer le dimanche.",
        panelDescription: "Mois, jours de la semaine et aujourd’hui."
    )

    static let it = CalendarPanelStrings(
        title: "Calendario",
        today: "Oggi",
        previousMonth: "Mese precedente",
        nextMonth: "Mese successivo",
        weekStartTitle: "La settimana inizia di lunedì",
        weekStartCaption: "Disattiva per iniziare di domenica.",
        panelDescription: "Mesi, giorni della settimana e oggi."
    )

    static let es = CalendarPanelStrings(
        title: "Calendario",
        today: "Hoy",
        previousMonth: "Mes anterior",
        nextMonth: "Mes siguiente",
        weekStartTitle: "La semana empieza en lunes",
        weekStartCaption: "Desactiva para empezar en domingo.",
        panelDescription: "Meses, días de la semana y hoy."
    )

    static let ptBR = CalendarPanelStrings(
        title: "Calendário",
        today: "Hoje",
        previousMonth: "Mês anterior",
        nextMonth: "Mês seguinte",
        weekStartTitle: "A semana começa na segunda-feira",
        weekStartCaption: "Desative para começar no domingo.",
        panelDescription: "Meses, dias da semana e hoje."
    )

    static let ru = CalendarPanelStrings(
        title: "Календарь",
        today: "Сегодня",
        previousMonth: "Предыдущий месяц",
        nextMonth: "Следующий месяц",
        weekStartTitle: "Неделя начинается с понедельника",
        weekStartCaption: "Выключите, чтобы начинать с воскресенья.",
        panelDescription: "Месяцы, дни недели и сегодня."
    )

    static let uk = CalendarPanelStrings(
        title: "Календар",
        today: "Сьогодні",
        previousMonth: "Попередній місяць",
        nextMonth: "Наступний місяць",
        weekStartTitle: "Тиждень починається з понеділка",
        weekStartCaption: "Вимкніть, щоб починати з неділі.",
        panelDescription: "Місяці, дні тижня й сьогодні."
    )

    static let tr = CalendarPanelStrings(
        title: "Takvim",
        today: "Bugün",
        previousMonth: "Önceki ay",
        nextMonth: "Sonraki ay",
        weekStartTitle: "Hafta pazartesi başlar",
        weekStartCaption: "Pazar günü başlaması için kapatın.",
        panelDescription: "Aylar, haftanın günleri ve bugün."
    )

    static let sk = CalendarPanelStrings(
        title: "Kalendár",
        today: "Dnes",
        previousMonth: "Predchádzajúci mesiac",
        nextMonth: "Nasledujúci mesiac",
        weekStartTitle: "Týždeň sa začína v pondelok",
        weekStartCaption: "Vypnutím začnete nedeľou.",
        panelDescription: "Mesiace, dni týždňa a dnes."
    )
}