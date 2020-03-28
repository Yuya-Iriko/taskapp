//
//  ViewController.swift
//  taskapp
//
//  Created by 入子優哉 on 2020/03/26.
//  Copyright © 2020 yuya.iriko. All rights reserved.
//

import UIKit
import RealmSwift
import UserNotifications

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addButton: UIBarButtonItem!
    
   
    let realm = try! Realm()
    var taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true)
    
    var searchActive: Bool = false
    var searchBar: UISearchBar! //検索バーを扱いやすくするための変数
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        //検索バー配置メソッド呼び出し
        //ここでデリゲート設定するとオブジェクトがないのでエラー
        setupSearchBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
    }
    
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //検索バー配置メソッド
    func setupSearchBar() {
        
        if let navigationBarFrame = navigationController?.navigationBar.bounds {
            let searchBar: UISearchBar = UISearchBar(frame: navigationBarFrame)
            searchBar.delegate = self
            searchBar.placeholder = "カテゴリー検索"
            searchBar.tintColor = UIColor.black
            searchBar.keyboardType = UIKeyboardType.default
            searchBar.enablesReturnKeyAutomatically = false
            navigationItem.titleView = searchBar
            //＋ボタンを勝手に避けてくれている
            navigationItem.titleView?.frame = searchBar.frame
            self.searchBar = searchBar
        }
    }
    
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.showsCancelButton = true
        addButton.isEnabled = false
        return true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true)
        tableView.reloadData()
        searchBar.showsCancelButton = false
        addButton.isEnabled = true
        searchBar.resignFirstResponder()
    }
    
    //テキストの入力に反応してメソッドが呼び出される
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if searchBar.text != nil {
            let predicate = NSPredicate(format: "category = %@", searchBar.text!)
            taskArray = realm.objects(Task.self).filter(predicate)
        }
        //テーブルを再読み込みする。
        tableView.reloadData()
    }
    
    
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tableView.reloadData()
    }
    
    //テーブルのリロード時に実行されるメソッド
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return taskArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let task = taskArray[indexPath.row]
        
        cell.textLabel?.text = task.title
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let dateString:String = formatter.string(from: task.date)
        
        cell.detailTextLabel?.text = dateString
        
        return cell
    }
    
    
    //画面遷移
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let inputViewController: InputViewController = segue.destination as! InputViewController
        
        if segue.identifier == "cellSegue" {
            let indexPath = self.tableView.indexPathForSelectedRow
            inputViewController.task = taskArray[indexPath!.row]
        } else {
            let task = Task()
            let allTasks = realm.objects(Task.self)
            if allTasks.count != 0 {
                task.id = allTasks.max(ofProperty: "id")! + 1
            }
            inputViewController.task = task
            
        }
        
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "cellSegue", sender: nil)
    }
    
    //削除実装
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete{
            try! realm.write {
                let task = self.taskArray[indexPath.row]//rowはこのメソッドで選択されているタスクを指定している
                
                let center = UNUserNotificationCenter.current()
                center.removePendingNotificationRequests(withIdentifiers: [String(task.id)])
                
                try! realm.write{
                    self.realm.delete(task)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                }
                //オブジェクトを生成する際に、Taskクラスを使って生成していることに留意
                
                center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
                for request in requests {
                    print("/---------------")
                    print(request)
                    print("---------------/")
                    }
                }
            }
        }
    }

}
