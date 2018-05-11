/**
* Copyright (c) 2017 Razeware LLC
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Notwithstanding the foregoing, you may not use, copy, modify, merge, publish, 
* distribute, sublicense, create a derivative work, and/or sell copies of the 
* Software in any work that is designed, intended, or marketed for pedagogical or 
* instructional purposes related to programming, coding, application development, 
* or information technology.  Permission for such use, copying, modification,
* merger, publication, distribution, sublicensing, creation of derivative works, 
* or sale is expressly withheld.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

import UIKit
import CoreData

class PetsViewController: UIViewController {
	@IBOutlet private weak var collectionView:UICollectionView!
	
    var friend : Friend!
    private var fetchedRC : NSFetchedResultsController<Pet>!
    var query = ""
    private var appDelegate = UIApplication.shared.delegate as! AppDelegate
    lazy private var context = appDelegate.persistentContainer.viewContext
    private let formater = DateFormatter()
	private var isFiltered = false

	private var selected:IndexPath!
	private var picker = UIImagePickerController()

    override func viewDidLoad() {
        super.viewDidLoad()
		picker.delegate = self
        formater.dateFormat = "d MMM yyyy"
        let longPres = UILongPressGestureRecognizer(target: self, action: #selector(delete(gesture:)))
        view.addGestureRecognizer(longPres)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refresh()
    }
    
    @objc func delete(gesture : UILongPressGestureRecognizer) {
        if gesture.state != .ended {
            return
        }
        let pos = gesture.location(in: view)
        if let indexPath = collectionView.indexPathForItem(at: pos) {
            let pet = fetchedRC.object(at: indexPath)
            context.delete(pet)
            appDelegate.saveContext()
        }
        
    }
    
    private func refresh() {
        let request = Pet.fetchRequest() as NSFetchRequest<Pet>
        if query.isEmpty {
            request.predicate = NSPredicate(format: "owner = %@", friend)
        }
        else {
            request.predicate = NSPredicate(format: "name CONTAINS[cd] %@ AND owner = %@", query, friend)
        }
        let sort = NSSortDescriptor(key: #keyPath(Pet.name), ascending: true, selector: #selector(NSString.caseInsensitiveCompare(_:)))
        request.sortDescriptors = [sort]
        do {
            fetchedRC = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
            try fetchedRC.performFetch()
            fetchedRC.delegate = self
        }
        catch {
            print(error.localizedDescription)
        }
    }

	// MARK:- Actions
	@IBAction func addPet() {
		let data = PetData()
        let pet = Pet(entity: Pet.entity(), insertInto: context)
        pet.name = data.name
        pet.dob = data.dob as NSDate
        pet.kind = data.kind
        pet.picture = data.picture as NSData?
        pet.owner = friend
        appDelegate.saveContext()
	}
}

// Collection View Delegates
extension PetsViewController: UICollectionViewDelegate, UICollectionViewDataSource {
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		
        guard let count = fetchedRC.fetchedObjects?.count else {
            return 0
        }
		return count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PetCell", for: indexPath) as! PetCell
		let pet = fetchedRC.object(at: indexPath)
		cell.nameLabel.text = pet.name
        cell.dobLabel.text = pet.kind
        if let dob = pet.dob {
            cell.dobLabel.text = formater.string(from: dob as Date)
        }
        else {
            cell.dobLabel.text = "unknown"
        }
        if let data = pet.picture as Data?, let image = UIImage(data: data) {
            cell.pictureImageView.image = image
        }
        else {
            cell.pictureImageView.image = #imageLiteral(resourceName: "pet-placeholder")
        }
        
		return cell
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		selected = indexPath
//		self.navigationController?.present(picker, animated: true, completion: nil)
	}
}

// Search Bar Delegate
extension PetsViewController:UISearchBarDelegate {
	func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
		guard let text = searchBar.text else {
			return
		}
		query = text
        refresh()
		searchBar.resignFirstResponder()
		collectionView.reloadData()
	}
	
	func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
		query = ""
        refresh()
		searchBar.text = nil
		searchBar.resignFirstResponder()
		collectionView.reloadData()
	}
}

// Image Picker Delegates
extension PetsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
		collectionView?.reloadItems(at: [selected])
        let pet = fetchedRC.object(at: selected)
        pet.picture = UIImagePNGRepresentation(image) as NSData?
        appDelegate.saveContext()
		picker.dismiss(animated: true, completion: nil)
	}
}

extension PetsViewController : NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        let index = indexPath ?? newIndexPath
        if let indexPath = index {
            switch type {
            case .insert:
                collectionView.insertItems(at: [indexPath])
            case .delete:
                collectionView.deleteItems(at: [indexPath])
            default:
                break
            }
        }
    }
}
