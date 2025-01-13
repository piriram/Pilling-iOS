import UIKit
import SnapKit

struct DashboardViewLayout {
    
    static func setupConstraints(
        in view: UIView,
        backgroundImageView: UIImageView,
        topButtonsView: DashboardTopButtonsView,
        containerView: UIView,
        infoView: DashboardMiddleView,
        stasticsView: StatisticsContentView,
        bottomView: DashboardBottomView
    ) {
        let contentInset: CGFloat = 16
        
        backgroundImageView.snp.makeConstraints { make in
            make.top.equalTo(view.snp.top)
            make.leading.trailing.equalToSuperview()
            make.bottom.greaterThanOrEqualTo(view.safeAreaLayoutGuide.snp.top).offset(220)
        }
        
        topButtonsView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(14)
            make.trailing.equalToSuperview().inset(contentInset)
            make.height.equalTo(30)
        }
        
        containerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
        }
        
        infoView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        stasticsView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        bottomView.snp.makeConstraints { make in
            make.top.equalTo(containerView.snp.bottom).offset(16)
            make.horizontalEdges.equalToSuperview().inset(contentInset)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
        }
    }
}
