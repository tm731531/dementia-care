"""Authoritative whiteboard layout confirmed by user 2026-04-14."""

# Left-to-right order of option boxes as physically drawn on the whiteboard
WHITEBOARD_LAYOUT = {
    "NightActivity":       ["完成", "未完成", "抗拒"],
    "BeforeSleepStatus":   ["正常", "疲倦", "亢奮"],
    "LastNightSleep":      ["良好", "斷續", "差"],
    "MorningMentalStatus": ["穩定", "煩躁", "嗜睡"],
    "Breakfast":           ["正常", "少", "拒食", "多"],
    "Lunch":               ["正常", "少", "拒食", "多"],
    "Dinner":              ["正常", "少", "拒食", "多"],
    "DailyActivity":       ["完成", "未完成", "抗拒"],
    "outgoing":            ["穩定", "疲倦", "抗拒"],  # NOTE: semantically different from iDempiere enum
    "Companionship":       ["穩定", "情緒不安", "疲倦"],
    "ExcretionStatus":     ["正常", "便秘", "稀"],
    "Bathing":             ["完成", "未完成", "抗拒"],
}

# Mapping from whiteboard labels to iDempiere enum values (id codes).
# None = unmapped, needs user decision.
WB_TO_IDEMPIERE = {
    "NightActivity": {
        "完成": "C", "未完成": "N", "抗拒": "S",
    },
    "BeforeSleepStatus": {
        "正常": "N", "疲倦": "S", "亢奮": "X",
    },
    "LastNightSleep": {
        "良好": "G", "斷續": "S", "差": "N",
    },
    "MorningMentalStatus": {
        "穩定": "N",
        "煩躁": "A",
        "嗜睡": "B",  # approximate map: 嗜睡 → 差 (user confirmed, 勉強映射)
    },
    "Breakfast": {
        "正常": "N", "少": "10000001", "拒食": "10000002", "多": "10000009",
    },
    "Lunch": {
        "正常": "N", "少": "10000001", "拒食": "10000002", "多": "10000009",
    },
    "Dinner": {
        "正常": "N", "少": "10000001", "拒食": "10000002", "多": "10000009",
    },
    "DailyActivity": {
        "完成": "C", "未完成": "N", "抗拒": "S",
    },
    "outgoing": {
        # Whiteboard labels reflect caregiver's real-world usability:
        # "完成/未完成" was too abstract; they reframed it as the patient's state during outing
        "穩定": "C",  # stable during outing → counts as completed
        "疲倦": "N",  # too tired → counts as not completed
        "抗拒": "S",  # refused → resistance (same as iDempiere)
    },
    "Companionship": {
        "穩定": "10000003",
        "情緒不安": "10000004",  # user confirmed: 情緒不安 → 坐立不安 (semantic equivalent)
        "疲倦": "10000005",
    },
    "ExcretionStatus": {
        "正常": "10000006", "便秘": "10000007", "稀": "10000008",
    },
    "Bathing": {
        "完成": "C", "未完成": "N", "抗拒": "S",
    },
}
