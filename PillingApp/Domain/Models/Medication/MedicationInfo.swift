import Foundation

struct MedicationInfo {
    let id: String
    let name: String
    let manufacturer: String
    let mainIngredient: String
    let materialName: String
    let dosageInstructions: String
    let packUnit: String
    let storageMethod: String
    let permitDate: String
}

extension MedicationInfo {
    var isContraceptivePill: Bool {
        let keywords = ["경구피임", "피임약", "피임제"]
        return keywords.contains { name.contains($0) }
    }

    func matchesSearchQuery(_ query: String) -> Bool {
        let normalizedQuery = query.lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "정", with: "")

        let normalizedName = name.lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "정", with: "")

        return normalizedName.contains(normalizedQuery)
    }

    func toPillInfo() -> PillInfo {
        let dosage = DosageParser.parse(dosageText: dosageInstructions)
        return PillInfo(
            name: name,
            takingDays: dosage.takingDays,
            breakDays: dosage.breakDays,
            manufacturer: manufacturer,
            mainIngredient: mainIngredient,
            dosageInstructions: dosageInstructions,
            itemSeq: id
        )
    }
}
