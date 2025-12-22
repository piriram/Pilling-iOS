import Foundation
import RxSwift

protocol MedicationAPIServiceProtocol {
    func fetchMedications(keyword: String) -> Observable<[MedicationInfo]>
}

final class MedicationAPIService: MedicationAPIServiceProtocol {

    private let baseURL = "https://apis.data.go.kr/1471000/DrugPrdtPrmsnInfoService07/getDrugPrdtPrmsnInq07"
    private let apiKey: String

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func fetchMedications(keyword: String) -> Observable<[MedicationInfo]> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(MedicationAPIError.invalidURL)
                return Disposables.create()
            }

            let encodedKeyword = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? keyword
            let urlString = "\(self.baseURL)?serviceKey=\(self.apiKey)&item_name=\(encodedKeyword)&type=json&pageNo=1&numOfRows=100"

            print("🔍 [API] Request URL: \(urlString)")
            print("🔍 [API] API Key length: \(self.apiKey.count)")

            guard let url = URL(string: urlString) else {
                observer.onError(MedicationAPIError.invalidURL)
                return Disposables.create()
            }

            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                if let error = error {
                    observer.onError(MedicationAPIError.networkError(error))
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    observer.onError(MedicationAPIError.invalidResponse)
                    return
                }

                guard (200...299).contains(httpResponse.statusCode) else {
                    observer.onError(MedicationAPIError.httpError(statusCode: httpResponse.statusCode))
                    return
                }

                guard let data = data else {
                    observer.onError(MedicationAPIError.invalidResponse)
                    return
                }

                if let responseString = String(data: data, encoding: .utf8) {
                    print("🔍 [API] Response: \(responseString.prefix(500))")
                }

                do {
                    let apiResponse = try JSONDecoder().decode(MedicationAPIResponse.self, from: data)

                    print("🔍 [API] Result Code: \(apiResponse.header.resultCode)")
                    print("🔍 [API] Result Message: \(apiResponse.header.resultMsg)")

                    if apiResponse.header.resultCode != "00" {
                        observer.onError(MedicationAPIError.apiError(
                            code: apiResponse.header.resultCode,
                            message: apiResponse.header.resultMsg
                        ))
                        return
                    }

                    let medications = apiResponse.body.items.map { $0.toDomainModel() }
                    observer.onNext(medications)
                    observer.onCompleted()

                } catch {
                    observer.onError(MedicationAPIError.decodingError(error))
                }
            }

            task.resume()

            return Disposables.create {
                task.cancel()
            }
        }
    }
}
