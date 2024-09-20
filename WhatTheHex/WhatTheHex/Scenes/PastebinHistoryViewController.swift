//
//  PastebinHistoryViewController.swift
//  WhatTheHex
//
//  Created by Ivan Evačić on 17.08.2024..
//

import UIKit

class PastebinHistoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    lazy var tableView = UITableView()
    
    private var colorHistory: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadColorHistory()
    }
    
    func setupTableView() {
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .lightGray
        tableView.showsVerticalScrollIndicator = false
        tableView.register(PastebinHistoryTableViewCell.self, forCellReuseIdentifier: "PastebinHistoryCell")
        setupConstraints()
    }
    
    func setupConstraints() {
        tableView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }
    
    private func loadColorHistory() {
        colorHistory = ColorHistoryService.shared.getColorHistory()
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return colorHistory.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PastebinHistoryCell", for: indexPath) as! PastebinHistoryTableViewCell
        cell.configure(with: colorHistory[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        UIPasteboard.general.string = colorHistory[indexPath.row]
        NotificationService.shared.showNotification(in: self.view, message: "Color \(colorHistory[indexPath.row]) copied to clipboard.")
    }
}

extension PastebinHistoryViewController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return BottomHalfPresentationController(presentedViewController: presented, presenting: presenting)
    }
}

