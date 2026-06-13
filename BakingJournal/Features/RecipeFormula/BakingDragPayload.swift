import CoreTransferable
import Foundation
import UniformTypeIdentifiers

struct StepMaterialDragPayload: Codable, Transferable {
    let id: UUID

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(contentType: .stepMaterialPayload) { payload in
            try JSONEncoder().encode(payload)
        } importing: { data in
            try JSONDecoder().decode(Self.self, from: data)
        }
    }
}

extension UTType {
    static let stepMaterialPayload = UTType(exportedAs: "com.openbakery.toastmark.step-material")
}
