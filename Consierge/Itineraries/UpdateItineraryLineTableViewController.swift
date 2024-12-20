//
//  UpdateItineraryLineTableViewController.swift
//  Consierge
//
//  Created by Austin McLaughlin on 12/7/24.
//

import UIKit

class UpdateItineraryLineTableViewController: UITableViewController {
    
    var itineraryLine: ItineraryLine
    let place: Place
    
    @IBOutlet var placePic: UIImageView!
    @IBOutlet var placeLabel: UILabel!
    @IBOutlet var datePicker: UIDatePicker!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var customNameText: UITextField!
    
    let addDateTimeIndexPath = IndexPath(row: 1, section: 0)
    let addCustomNoteIndexPath = IndexPath(row: 2, section: 0)
    
    let dateLabelsIndexPath = IndexPath(row: 3, section: 0)
    let datePickerIndexPath = IndexPath(row: 4, section: 0)
    let customNoteIndexPath = IndexPath(row: 5, section: 0)
    
    var addDateTimeVisible = true
    var addCustomNoteVisible = true
    var dateTimeVisible = false
    var datePickerVisible = false
    var customNoteVisible = false
    
    weak var delegate: UpdateItineraryLineTableViewControllerDelegate?
    
    var imageRequestTask: Task<Void,Never>? = nil
    
    deinit {
        imageRequestTask?.cancel()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //fetch image for the place and set the place.Name in the label
        updatePlace()
        
        //fill in the existing ItineraryLine data
        fillInExistingData()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    init?(coder: NSCoder, itineraryLine: ItineraryLine, place: Place) {
        //initialize required Place & ItineraryLine values
        self.place = place
        self.itineraryLine = itineraryLine
        super.init(coder: coder)
    }
    
    func updatePlace() {
        switch place.self {
        case is FSQPlace:
            fetchFSQImage(imageURL: place.imageURL)
        case is GooglePlace:
            fetchGoogleImage(photoReference: place.imageURL)
        default:
            //fetch image for the place and set the place.Name in the label
            self.imageRequestTask = Task {
                if let image = try? await ImageRequest(path: place.imageURL).send() {
                    placePic.image = image
                }
                self.imageRequestTask = nil
            }
        }
        placeLabel.text = place.name
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        //sets each row's height based on IndexPath and isVisible indicators intiated at the top and updated with addDate and addNote cells
        switch indexPath {
        case addDateTimeIndexPath where addDateTimeVisible == false:
            return 0
        case addCustomNoteIndexPath where addCustomNoteVisible == false:
            return 0
        case dateLabelsIndexPath where dateTimeVisible == false:
            return 0
        case datePickerIndexPath where dateTimeVisible == false || datePickerVisible == false:
            return 0
        case customNoteIndexPath where customNoteVisible == false:
            return 0
        default:
            return UITableView.automaticDimension
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        //show Date/Time or Custom Note or make datepicker visible/hidden
        switch indexPath {
        case addDateTimeIndexPath:
            addDateTimeVisible = false
            dateTimeVisible = true
            datePickerVisible = true
            updateDate()
        case addCustomNoteIndexPath:
            addCustomNoteVisible = false
            customNoteVisible = true
        case dateLabelsIndexPath:
            datePickerVisible.toggle()
        default:
            break
        }
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    func updateDate() {
        dateLabel.text = datePicker.date.formatted(date: .abbreviated, time: .shortened)
    }
    
    
    @IBAction func dateChanged(_ sender: Any) {
        updateDate()
    }
    
    func fillInExistingData(){
        //fill in the existing ItineraryLine data
        let midnightToday = Calendar.current.startOfDay(for: Date())
        datePicker.minimumDate = midnightToday
        
        if let startDate = itineraryLine.startDateDate {
            addDateTimeVisible = false
            dateTimeVisible = true
            datePickerVisible = true
            if midnightToday > startDate {
                datePicker.minimumDate = startDate
            }
            datePicker.date = startDate
            updateDate()
        }
        
        if itineraryLine.customNote != "" {
            addCustomNoteVisible = false
            customNoteVisible = true
            customNameText.text = itineraryLine.customNote
        }
    }
    
    @IBAction func donePressed(_ sender: Any) {
        //Capture each of the values if they were changed and update the ItineraryLine object passed in.
        //Send API Request to update ItineraryLine
        
        var startDate: String? = nil

        if dateTimeVisible == true {
            startDate = datePicker.date.ISO8601Format()
        }
        
        var customNote: String? = nil
        if customNoteVisible == true {
            customNote = customNameText.text
        }
        
        itineraryLine.startDate = startDate
        itineraryLine.customNote = customNote ?? ""
        
        Task {
            let resultValue = try? await UpdateItineraryLineRequest(itineraryLine: itineraryLine).send()
            if let resultValue = resultValue {
                if resultValue["status"] == "Success" {
                    self.delegate?.updateItineraryLineTableViewController(self)
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
}

protocol UpdateItineraryLineTableViewControllerDelegate: AnyObject {
    func updateItineraryLineTableViewController(_ controller: UpdateItineraryLineTableViewController)
}


extension UpdateItineraryLineTableViewController {
    func fetchFSQImage(imageURL: String)  {
        imageRequestTask = Task {
            do {
                let image = try await fetchFSQImageThrows(url: URL(string: imageURL)!)
                self.placePic.image = image
            } catch {
                self.placePic.image = nil
            }
        }
    }
    
    func fetchFSQImageThrows(url: URL) async throws -> UIImage {
        enum PhotoInfoError: Error, LocalizedError {
            case itemNotFound
            case imageDataMissing
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw PhotoInfoError.imageDataMissing
        }
        
        guard let image = UIImage(data: data) else {
            throw PhotoInfoError.imageDataMissing
        }
        
        return image
    }
    
    func fetchGoogleImage(photoReference: String)  {
        imageRequestTask = Task {
            if let image  = try? await GooglePlacePhotoRequest(photo_reference: photoReference).send() {
                self.placePic.image = image
            } else {
                self.placePic.image = nil
            }
        }
    }
    func fetchGoogleImageThrows(url: URL) async throws -> UIImage {
        enum PhotoInfoError: Error, LocalizedError {
            case itemNotFound
            case imageDataMissing
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw PhotoInfoError.imageDataMissing
        }
        
        guard let image = UIImage(data: data) else {
            throw PhotoInfoError.imageDataMissing
        }
        
        return image
    }
}
