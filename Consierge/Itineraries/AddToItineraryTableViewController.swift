//
//  AddToItineraryTableViewController.swift
//  Consierge
//
//  Created by Austin McLaughlin on 11/30/24.
//

import UIKit

class AddToItineraryTableViewController: UITableViewController, UITextFieldDelegate {
    
    //initiate place, city, type to pass via prepareToSegue
    var place: Place?
    var cityID: City?
    var type: String?
    var isFSQPlace = false
    var isGooglePlace = false
    enum UnwindTo {
        case askAI
        case uhCity
        case placeDeets
        case userAccount
    }
    var whereToUnwind: UnwindTo = .placeDeets
    
    var added = false
    
    @IBOutlet var placePic: UIImageView!
    @IBOutlet var placeLabel: UILabel!
    
    @IBOutlet var itineraryNameText: UITextField!
    @IBOutlet var itineraryLabel: UILabel!
    
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var datePicker: UIDatePicker!
    
    @IBOutlet var customNoteText: UITextField!
    
    @IBOutlet var doneButton: UIBarButtonItem!
    
    //setup indexPaths in order to show/hide and set height
    let itineraryNameIndexPath = IndexPath(row: 1, section: 0)
    
    let addDateTimeIndexPath = IndexPath(row: 1, section: 1)
    let addCustomNoteIndexPath = IndexPath(row: 2, section: 1)
    
    let dateLabelsIndexPath = IndexPath(row: 3, section: 1)
    let datePickerIndexPath = IndexPath(row: 4, section: 1)
    let customNoteIndexPath = IndexPath(row: 5, section: 1)
    
    //initiate indicators to tell whether sections are shown/hidden
    var isNewItinerary = false
    
    var addDateTimeVisible = true
    var addCustomNoteVisible = true
    
    var dateTimeVisible = false
    var datePickerVisible = false
    var customNoteVisible = false
    
    //initiate chosen itinerary, nil if new
    var chosenItinerary: Itinerary?
    
    //initiate Image API task and cancel
    var imageRequestTask: Task<Void,Never>? = nil
    deinit {
        imageRequestTask?.cancel()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //assign type of restaurant, cafe, bar, activity, fsq___, or google___
        getType()
        //sets Place image and name
        updatePlace()
        
        //set minimum date
        let midnightToday = Calendar.current.startOfDay(for: Date())
        datePicker.minimumDate = midnightToday
        
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        itineraryNameText.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //if Itinerary is selected set name/else make it "none"
        updateItinerary()
    }
    
    func updatePlace() {
        print("isfsq", isFSQPlace)
        print("isGoogly", isGooglePlace)
        print("place image url", place?.imageURL ?? "NONE!!!!!!!")
        switch (isFSQPlace, isGooglePlace) {
        case (true, _):
            if let place = place {
                fetchFSQImage(imageURL: place.imageURL)
            }
        case (_, true):
            if let place = place {
                fetchGoogleImage(photoReference: place.imageURL)
            }
        default:
            self.imageRequestTask = Task {
                if let image = try? await ImageRequest(path: place?.imageURL ?? "").send() {
                    placePic.image = image
                }
                self.imageRequestTask = nil
            }
        }
        
        placeLabel.text = place?.name
    }
    
    func getType() {
        switch place.self {
        case is GooglePlace:
            isGooglePlace = true
            isFSQPlace = false
            switch type {
            case "restaurant":
                type = "googleRestaurant"
            case "cafe":
                type = "googleCafe"
            case "bar":
                type = "googleBar"
            default:
                type = "googleActivity"
            }
        case is FSQPlace:
            isFSQPlace = true
            isGooglePlace = false
            switch type {
            case "restaurant":
                type = "fsqRestaurant"
            case "cafe":
                type = "fsqCafe"
            case "bar":
                type = "fsqBar"
            default:
                type = "fsqActivity"
            }
        default:
            isFSQPlace = false
            isGooglePlace = false
        }
    }
    
    func updateDate() {
        //used anytime the datePicker is altered
        dateLabel.text = datePicker.date.formatted(date: .abbreviated, time: .shortened)
    }
    
    @IBAction func updateDate(_ sender: Any) {
        updateDate()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        //sets each row's height based on IndexPath and isVisible indicators intiated at the top and updated with addDate and addNote cells
        switch indexPath {
        case itineraryNameIndexPath where isNewItinerary == false:
            return 0
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
    
    @IBSegueAction func addItinerary(_ coder: NSCoder) -> PickItineraryTableViewController? {
        //segue to PickItinerary with city and type
        let pickItineraryController = PickItineraryTableViewController(coder: coder, type: type, city: cityID)
        pickItineraryController?.delegate = self
        pickItineraryController?.selectedItinerary = chosenItinerary
        pickItineraryController?.placeImageURL = place?.imageURL
        return pickItineraryController
    }
    
    func doneTapped() {
        if added { return }
        added = true
        //get date if there is one
        var startDate: String? = nil
        if dateTimeVisible == true {
            startDate = datePicker.date.ISO8601Format()
        }
        
        var customNote: String? = nil
        if customNoteVisible == true {
            customNote = customNoteText.text
        }
        
        //chosenItinerary set when passed from PickItinterary; whether existing or new
        //If a name is typed assign name; if blank create default name.
        guard var chosenItinerary = chosenItinerary else { return }
        
        //create Itinerary Line with Itinerary, Place, Date, and Note
        let itineraryLine = ItineraryLine(ID: 0, itineraryID: chosenItinerary.ID, placeID: place?.id ?? 0, fsqID: place?.fsqID ?? "", placeName: place?.name ?? "Joes Diner",type: type ?? "", startDate: startDate ?? "", customNote: customNote ?? "")
        
        if let name = itineraryNameText.text, name != "" {
            chosenItinerary.name = name
        } else {
            let dateFormatted = chosenItinerary.createdDateDate?.formatted(date: .abbreviated, time: .omitted)
            
            chosenItinerary.name = "\(cityID?.name ?? "Itinerary") - created on \(dateFormatted ?? "08/02/1960")"
        }
        
        //create model to pass to DB
        let newItinerary = ItineraryWithLine(itinerary: chosenItinerary, itineraryLine: itineraryLine)
        
        Task {
            //if new Itinerary run BrandNew API
            //if existing Itinerary run NewLine API
            print("2")
            if isNewItinerary {
                let resultValue = try? await BrandNewItineraryRequest(itinerary: newItinerary).send()
                if let resultValue = resultValue {
                    print("3")
                    if resultValue["status"] == "Success" {
                        print("4")
                    } else {
                        print(resultValue)
                    }
                } else {
                    print("error")
                }
            } else {
                let resultValue = try? await NewItineraryLineRequest(itinerary: newItinerary).send()
                if let resultValue = resultValue {
                    print(newItinerary)
                    if resultValue["status"] == "Success" {
                        switch whereToUnwind {
                        case .placeDeets:
                            performSegue(withIdentifier: "UnwindToPlaceDeets", sender: nil)
                        case .uhCity:
                            performSegue(withIdentifier: "UnwindToACity", sender: nil)
                        case .askAI:
                            performSegue(withIdentifier: "UnwindToAskAI", sender: nil)
                        case .userAccount:
                            performSegue(withIdentifier: "UnwindToUserAccount", sender: nil)
                        }
                    } else {
                        print(resultValue)
                    }
                } else {
                    print("error")
                }
            }
        }
            
    }
    
    
    @IBAction func cancelClicked(_ sender: Any) {
        switch whereToUnwind {
        case .placeDeets:
            performSegue(withIdentifier: "FinishItineraryAdd", sender: nil)
        case .uhCity:
            performSegue(withIdentifier: "UnwindToACity", sender: nil)
        case .askAI:
            performSegue(withIdentifier: "UnwindToAskAI", sender: nil)
        case .userAccount:
            performSegue(withIdentifier: "UnwindToUserAccount", sender: nil)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard ["UnwindToPlaceDeets", "UnwindToACity", "UnwindToAskAI", "UnwindToUserAccount"].contains(segue.identifier) else { return }
        doneTapped()
    }
}

extension AddToItineraryTableViewController: PickItineraryTableViewControllerDelegate {
    
    func pickItineraryTableViewController(_ controller: PickItineraryTableViewController, didSelect itinerary: Itinerary) {
        //Delegate function for PickItinerary. See func inside of Protocol in the following VC
        //allows Itinerary to be passed back; same as the Neighborhood/Genre model in NewRestaurant
        self.chosenItinerary = itinerary
        
        if itinerary.name == "New" {
            isNewItinerary = true
        } else {
            isNewItinerary = false
        }
        updateItinerary()
        tableView.reloadData()
    }
    
    func updateItinerary() {
        //Updates itinerary text
        if let chosenItinerary = chosenItinerary {
            itineraryLabel.text = chosenItinerary.name
        } else {
            itineraryLabel.text = "none"
        }
        updateSaveButtonState()
    }
    
    func updateSaveButtonState(){
        //blocks user from updating until an Itinerary is chose
        let shouldDoneEnabled = chosenItinerary != nil
        doneButton.isEnabled = shouldDoneEnabled
    }
}

extension AddToItineraryTableViewController {
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
