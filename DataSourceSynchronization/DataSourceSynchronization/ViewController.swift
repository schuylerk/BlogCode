//
//  ViewController.swift
//  DataSourceSynchronization
//
//  Created by schuyler on 2023/3/19.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var dynamicData = [
        Dynamic(title: "重庆火锅到底卷成什么样子了？还能涮牛窝骨!", pic: "http://i2.hdslb.com/bfs/archive/1f5083d48bd6a11bda11b47d4f862341744a1a04.jpg"),
        Dynamic(title: "大肠拌饭太香了,路人为我的光盘行动鼓掌!", pic: "http://i0.hdslb.com/bfs/archive/aa0608b4d801441f7dea96e55da125f007a75c70.jpg"),
        Dynamic(title: "杭州街头偶遇治愈系路边摊,终于吃到了梅花糕,粘酱麻薯,木瓜沙拉!", pic: "http://i2.hdslb.com/bfs/archive/82726f9420fe215f9a49affdae09d17dfb39c562.jpg"),
        Dynamic(title: "美女深夜去吃街边炸鸡,一口下去竟然疯狂爆汁!", pic: "http://i0.hdslb.com/bfs/archive/9179e0e1244b6f9208737ae36f9d972020fe605b.jpg")
    ]
    
    let dynamicReusedID = "table.cell.dynamic"
    
    var deleteIndexes: [Int] = []
    
    lazy var tableView: UITableView = {
        let tbv = UITableView(frame: CGRect(x: 0, y: 100, width: view.bounds.width, height: view.bounds.height - 100))
        tbv.delegate = self
        tbv.dataSource = self
        tbv.separatorStyle = .none
        tbv.showsVerticalScrollIndicator = false
        tbv.register(DynamicCell.self, forCellReuseIdentifier: dynamicReusedID)
        return tbv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "小紧张的虫虫"
        view.backgroundColor = .white
        view.addSubview(tableView)
        
        fetchImageData(dynamicData) { [self] data in
            dynamicData = data
            deleteIndexes.forEach { dynamicData.remove(at: $0) }
            deleteIndexes = []
            DispatchQueue.main.sync {
                tableView.reloadData()
            }
        }
    }
    
    func fetchImageData(_ dynamicData: [Dynamic], completion: @escaping ([Dynamic]) -> Void) {
        var data = dynamicData
        var count = 0
        for i in 0..<data.count {
            if let url = URL(string: data[i].pic) {
                let task = URLSession.shared.dataTask(with: url) { imageData, _, _ in
                    if let imageData = imageData {
                        data[i].imageData = imageData
                    }
                    count -= 1
                    if count == 0 {
                        sleep(1)
                        completion(data)
                    }
                }
                task.resume()
                count += 1
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dynamicData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: dynamicReusedID, for: indexPath) as? DynamicCell else {
            return UITableViewCell()
        }
        cell.updateView(data: dynamicData[indexPath.row])
        cell.delete = {
            self.dynamicData.remove(at: indexPath.row)
            self.deleteIndexes.append(indexPath.row)
            tableView.reloadData()
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return DynamicCell.calculateHeight(data: dynamicData[indexPath.row], width: Double(view.bounds.width - 10))
    }

}

class DynamicCell: UITableViewCell {
    var delete: (() -> Void)?
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = .systemFont(ofSize: 15)
        label.numberOfLines = 0
        return label
    }()
    
    lazy var coverImageView: UIImageView = {
        let imgv = UIImageView()
        return imgv
    }()
    
    lazy var deleteButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "delete"), for: .normal)
        button.addTarget(self, action: #selector(tapDeleteButton), for: .touchUpInside)
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(coverImageView)
        contentView.addSubview(deleteButton)
    }
    
    func updateView(data: Dynamic) {
        deleteButton.frame = CGRect(x: bounds.width - 25, y: 5, width: 20, height: 20)
        titleLabel.text = data.title
        let titleSize = DynamicCell.calculateTextSize(data.title, width: bounds.width - 10)
        titleLabel.frame = CGRect(x: 5, y: 5, width: titleSize.width, height: titleSize.height)
        if let imageData = data.imageData {
            if let image = UIImage(data: imageData) {
                let imageSize = DynamicCell.calculateImageSize(image, width: bounds.width - 10)
                coverImageView.frame = CGRect(x: 5, y: 5 + titleSize.height + 10, width: imageSize.width, height: imageSize.height)
                coverImageView.image = image
            }
        }
    }
    
    @objc func tapDeleteButton() {
        delete?()
    }
    
    static func calculateTextSize(_ text: String, width: Double) -> CGSize {
        let rect = NSString(string: text).boundingRect(with: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude), options: [.usesLineFragmentOrigin], attributes: [.font: UIFont.systemFont(ofSize: 15)], context: nil)
        return rect.size
    }
    
    static func calculateImageSize(_ image: UIImage, width: Double) -> CGSize {
        let size = image.size
        let height = width * size.height / size.width
        return CGSize(width: width, height: height)
    }
    
    static func calculateHeight(data: Dynamic, width: Double) -> Double {
        var height: Double = 10
        let size = calculateTextSize(data.title, width: width)
        height += size.height
        if let imageData = data.imageData {
            if let image = UIImage(data: imageData) {
                height += calculateImageSize(image, width: width).height + 10
            }
        }
        return height
    }
    
}
