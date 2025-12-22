import UIKit
import SnapKit
import Kingfisher

final class MedicationSearchTableViewCell: UITableViewCell {

    static let identifier = "MedicationSearchTableViewCell"

    private let medicationImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 6
        imageView.tintColor = .lightGray
        imageView.image = UIImage(systemName: "pills")
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .black
        return label
    }()

    private let manufacturerLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .gray
        return label
    }()

    private let ingredientLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .lightGray
        label.numberOfLines = 1
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        medicationImageView.kf.cancelDownloadTask()
        medicationImageView.image = UIImage(systemName: "pills")
    }

    private func setupUI() {
        contentView.addSubview(medicationImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(manufacturerLabel)
        contentView.addSubview(ingredientLabel)

        medicationImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(48)
        }

        nameLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.equalTo(medicationImageView.snp.trailing).offset(12)
            $0.trailing.equalToSuperview().inset(16)
        }

        manufacturerLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(4)
            $0.leading.equalTo(medicationImageView.snp.trailing).offset(12)
            $0.trailing.equalToSuperview().inset(16)
        }

        ingredientLabel.snp.makeConstraints {
            $0.top.equalTo(manufacturerLabel.snp.bottom).offset(2)
            $0.leading.equalTo(medicationImageView.snp.trailing).offset(12)
            $0.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().offset(-12)
        }
    }

    func configure(with medication: MedicationInfo) {
        nameLabel.text = medication.name
        let typeText = medication.productTypeDisplay
        let dosageText = medication.dosagePatternText
        if !typeText.isEmpty {
            manufacturerLabel.text = "\(dosageText) · \(typeText)"
        } else {
            manufacturerLabel.text = dosageText
        }
        ingredientLabel.text = medication.mainIngredient
        setImage(urlString: medication.imageURL)
    }

    private func setImage(urlString: String) {
        guard !urlString.isEmpty, let url = URL(string: urlString) else {
            medicationImageView.image = UIImage(systemName: "pills")
            return
        }

        medicationImageView.kf.setImage(
            with: url,
            placeholder: UIImage(systemName: "pills"),
            options: [
                .cacheOriginalImage,
                .transition(.fade(0.2))
            ]
        )
    }
}
