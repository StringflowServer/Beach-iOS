//
//  CreateGroupViewController.swift
//  Beach
//
//  Created by Shubham Garg on 22/08/18.
//  Copyright © 2018 AlterBasics. All rights reserved.
//

import UIKit
import SF_swift_framework

class CreateGroupViewController: UIViewController {
    @IBOutlet weak var deleteGroupBtn:UIButton!
    @IBOutlet weak var selectedMembersLbl: UILabel!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var groupSubjectLbl: UITextField!
    @IBOutlet weak var membersTableView: UITableView!
    var isGroupEditing: Bool = false
    var membersArray:[Rosters] = []
    var activeSearch:Bool = false
    var searchArray:Array<Rosters> = []
    var selectedArray:Array<Rosters> = []
    var group:Rosters!
    var isOwner:Bool = false
    private var queue:DispatchQueue = DispatchQueue.init(label: "queue")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.membersTableView.tableFooterView = UIView(frame: .zero)
        self.membersTableView.delegate = self
        self.membersTableView.dataSource = self
        groupSubjectLbl.delegate = self
        searchBar.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        deleteGroupBtn.isHidden = true
        if isGroupEditing{
            if isOwner {
                deleteGroupBtn.isHidden = false
            }
            searchBar.isHidden = true
            selectedMembersLbl.isHidden = true
            self.title = "Edit Group"
            if group.room_subject != nil && ((group.room_subject?.replacingOccurrences(of: " ", with: "")) != ""){
                self.groupSubjectLbl.text = group.room_subject
            }
            else{
                self.groupSubjectLbl.text = group.name
            }
            
            self.getRosterDataWithOutGroupMembers()
            let barButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(self.editGroup))
            barButton.tintColor = .white
            self.navigationItem.rightBarButtonItem = barButton
        }
        else{
            searchBar.isHidden = true
            selectedMembersLbl.isHidden = true
            self.getRosterData()
            self.title = "Create Group"
            let barButton = UIBarButtonItem(title: "Create", style: .plain, target: self, action: #selector(self.createGroup))
            barButton.tintColor = .white
            self.navigationItem.rightBarButtonItem = barButton
        }
    }
    
    func getRosterData(){
        SFCoreDataManager.sharedInstance.getInfoFromDataBase(entityName: "Rosters",jid: nil, success: { (rosters:[Rosters]) in
            let sortedArray = rosters.sorted {$0.name?.localizedCaseInsensitiveCompare($1.name!) == ComparisonResult.orderedAscending }
            self.membersArray = sortedArray.filter({ (roster) -> Bool in
                if roster.is_group {
                    return false
                }
                return true
            })
            DispatchQueue.main.async {
                if self.membersArray.count > 0 {
                    self.searchBar.isHidden = false
                }
                self.membersTableView.reloadData()
            }
            
        }, failure: { (String) in
            print(String)
        })
    }
    
    func getRosterDataWithOutGroupMembers(){
        SFCoreDataManager.sharedInstance.getInfoFromDataBase(entityName: "Rosters",jid: nil, success: { (rosters:[Rosters]) in
            let sortedArray = rosters.sorted {$0.name?.localizedCaseInsensitiveCompare($1.name!) == ComparisonResult.orderedAscending }
            self.membersArray = sortedArray.filter({ (roster) -> Bool in
                if roster.is_group  {
                    return false
                }
                for member in Array(self.group.members!) as! [ChatRoomMembers]{
                    if (member.jid?.elementsEqual(roster.jid!))!{
                        return false
                    }
                }
                return true
            })
            
            DispatchQueue.main.async {
                if self.membersArray.count > 0 {
                    self.searchBar.isHidden = false
                    self.membersTableView.reloadData()
                }
                else {
                    let label = UILabel()
                    label.text = "NO member found"
                    self.membersTableView.backgroundView = label
                }
                
            }
            
        }, failure: { (String) in
            print(String)
        })
    }
    
    @objc public func editGroup(){
        do{
            if self.groupSubjectLbl.text != self.group.room_subject && self.groupSubjectLbl.text?.replacingOccurrences(of: " ", with: "") != "" {
                _ = try Platform.getInstance().getUserManager().updateRoomSubject(roomJID:  JID(jid:self.group.jid), subject: self.groupSubjectLbl.text!)
            }
            
            for member in self.selectedArray{
                _ = try Platform.getInstance().getUserManager().sendAddChatRoomMemberRequest(roomJID: JID(jid:self.group.jid), userJID: JID(jid:member.jid))
            }
            Constants.appDelegate.hideActivitiIndicaterView()
            self.navigationController?.popViewController(animated: true)
        }
        catch{
            print(error.localizedDescription)
        }
    }
    
    @objc public func createGroup(){
        if let name = groupSubjectLbl.text{
            Constants.appDelegate.addActivitiIndicaterView()
            do{
                var members:[JID] = []
                for member in self.selectedArray{
                    try members.append(JID(jid:member.jid))
                }
                queue.async {
                    let created = Platform.getInstance().getUserManager().createPrivateGroup(groupName: name, members: members)
                    DispatchQueue.main.async {
                        if !created{
                            let alert = UIAlertController(title: nil, message: "Unable to create group.Please Try again.", preferredStyle: .alert)
                            let ok = UIAlertAction(title: "OK", style:.default, handler: nil)
                            alert.addAction(ok)
                            self.present(alert, animated: true, completion: nil)
                        }
                        else{
                            
                            Constants.appDelegate.hideActivitiIndicaterView()
                            self.navigationController?.popViewController(animated: true)
                        }
                    }
                    
                }
                
            }
            catch{
                print(error.localizedDescription)
            }
        }
        else{
            let alert = UIAlertController(title: nil, message: "Please enter a group name", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style:.default, handler: nil)
            alert.addAction(ok)
            present(alert, animated: true, completion: nil)
        }
    }
    
    //MARK:- KeyBoard Hide
    //Calls this function when the tap is recognized.
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        self.searchBar.resignFirstResponder()
        view.endEditing(true)
    }
    
    @IBAction func deleteGrpBtnAxn(_ sender: Any) {
        let alertController = UIAlertController(title: "Are you sure you want to delete group", message: "", preferredStyle: .alert)
        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Enter Reason"
        }
        let saveAction = UIAlertAction(title: "Delete", style: .default, handler: { alert -> Void in
            let reason = (alertController.textFields?.first?.text!)!
            self.queue.async {
                let deleted  = try? Platform.getInstance().getUserManager().destroyChatRoom(roomJID: JID(jid: self.group.jid), reason: reason)
                if deleted!{
                    DispatchQueue.main.async {
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                    
                }
                else{
                    DispatchQueue.main.async {
                    let alert = UIAlertController(title: nil, message: "Unable to delete", preferredStyle: .alert)
                    let ok = UIAlertAction(title: "OK", style:.default, handler: nil)
                    alert.addAction(ok)
                    self.present(alert, animated: true, completion: nil)
                    }
                }
                
            }
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action : UIAlertAction!) -> Void in })
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
        
        
    }
    
    
    
}





extension CreateGroupViewController :UITableViewDelegate,UITableViewDataSource{
    
    // MARK: - Table view data source
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.activeSearch
        {
            return self.searchArray.count
        }
        
        return self.membersArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactsTableViewCell", for: indexPath) as? ContactsTableViewCell
        cell?.userSelectedImageView.isHidden  = true
        if activeSearch {
            cell?.userImageImageView.image = #imageLiteral(resourceName: "profile")
            cell?.userNameUILabel.text = searchArray[indexPath.row].name
            if selectedArray.contains(searchArray[indexPath.row]){
                cell?.accessoryType = .checkmark
            }
            else{
                cell?.accessoryType = .none
            }
        }
        else {
            cell?.userNameUILabel.text = membersArray[indexPath.row].name
            cell?.userImageImageView.image = #imageLiteral(resourceName: "profile")
            if selectedArray.contains(membersArray[indexPath.row]){
                cell?.accessoryType = .checkmark
            }
            else{
                cell?.accessoryType = .none
            }
        }
        
        return cell!
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        if activeSearch{
            if !selectedArray.contains(searchArray[indexPath.row]){
                tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
                selectedArray.append(searchArray[indexPath.row])
                selectedMembersLbl.isHidden = false
                selectedMembersLbl.text = selectedArray.compactMap({$0.name}).joined(separator: ",")
            }
            else{
                tableView.cellForRow(at: indexPath)?.accessoryType = .none
                selectedArray =  selectedArray.filter {$0 != searchArray[indexPath.row]}
                if selectedArray.count>0 {
                    selectedMembersLbl.isHidden = false
                    selectedMembersLbl.text = selectedArray.compactMap({$0.name}).joined(separator: ",")
                }
                else{
                    selectedMembersLbl.isHidden = true
                }
            }
        }
        else{
            if !selectedArray.contains(membersArray[indexPath.row]){
                tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
                selectedArray.append(membersArray[indexPath.row])
                selectedMembersLbl.isHidden = false
                selectedMembersLbl.text = selectedArray.compactMap({$0.name}).joined(separator: ",")
            }
            else{
                tableView.cellForRow(at: indexPath)?.accessoryType = .none
                selectedArray =  selectedArray.filter {$0 != membersArray[indexPath.row]}
                if selectedArray.count>0 {
                    selectedMembersLbl.isHidden = false
                    selectedMembersLbl.text = selectedArray.compactMap({$0.name}).joined(separator: ",")
                }
                else{
                    selectedMembersLbl.isHidden = true
                }
            }
        }
    }
}




// MARK: -  Search Bar Delegate Function
extension CreateGroupViewController : UISearchBarDelegate{
    
    public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        //self.activeSearch = true;
        
    }
    
    public func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        
    }
    
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.activeSearch = false;
        self.searchBar.resignFirstResponder()
    }
    
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.activeSearch = false;
        self.searchBar.resignFirstResponder()
    }
    
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if( searchText.isEmpty){
            self.activeSearch = false;
            self.searchBar.isSearchResultsButtonSelected = false
            self.searchBar.resignFirstResponder()
        } else {
            self.activeSearch = true;
            self.searchArray = self.membersArray.filter({ (user) -> Bool in
                let tmp: NSString = user.name! as NSString
                let range = tmp.range(of: searchText, options: NSString.CompareOptions.caseInsensitive)
                return range.location != NSNotFound
            })
        }
        self.membersTableView.reloadData()
    }
    
}

//MARK:- Text Fields delegate function
extension CreateGroupViewController:UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.groupSubjectLbl.endEditing(true)
        self.view.endEditing(true)
        return true
    }
}
