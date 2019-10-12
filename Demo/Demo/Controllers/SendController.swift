import UIKit
import RxSwift

class SendController: UIViewController {
    private let disposeBag = DisposeBag()

    @IBOutlet weak var addressTextField: UITextField?
    @IBOutlet weak var amountTextField: UITextField?
    @IBOutlet weak var coinLabel: UILabel?
    @IBOutlet weak var feeLabel: UILabel?
    @IBOutlet weak var timeLockSwitch: UISwitch?
    @IBOutlet weak var datePicker: UIDatePicker?

    private var adapters = [BaseAdapter]()
    private let segmentedControl = UISegmentedControl()
    private var timeLockEnabled = false

    override func viewDidLoad() {
        super.viewDidLoad()

        segmentedControl.addTarget(self, action: #selector(onSegmentChanged), for: .valueChanged)

        Manager.shared.adapterSignal
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    self?.updateAdapters()
                })
                .disposed(by: disposeBag)

        updateAdapters()
    }

    private func updateAdapters() {
        segmentedControl.removeAllSegments()

        adapters = Manager.shared.adapters

        for (index, adapter) in adapters.enumerated() {
            segmentedControl.insertSegment(withTitle: adapter.coinCode, at: index, animated: false)
        }

        navigationItem.titleView = segmentedControl

        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.sendActions(for: .valueChanged)
    }
    
    private func updateFee() {
        guard let address = addressTextField?.text else {
            feeLabel?.text = "Fee: "
            return
        }

        do {
            try currentAdapter?.validate(address: address)
        } catch {
            feeLabel?.text = "Fee: "
            return
        }

        guard let amountString = amountTextField?.text, let amount = Decimal(string: amountString) else {
            feeLabel?.text = "Fee: "
            return
        }
        
        var pluginData = [String: [String: Any]]()
        if let lockUntil = datePicker?.date, timeLockEnabled {
            pluginData["hodler"] = ["locked_until": Int(lockUntil.timeIntervalSince1970)]
        }
        
        if let fee = currentAdapter?.fee(for: amount, address: address, pluginData: pluginData) {
            feeLabel?.text = "Fee: \(fee)"
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        view.endEditing(true)
    }
    
    @objc func onSegmentChanged() {
        coinLabel?.text = currentAdapter?.coinCode
        updateFee()
    }
    
    @IBAction func onAddressEditEnded(_ sender: Any) {
        updateFee()
    }
    
    @IBAction func onAmountEditEnded(_ sender: Any) {
        updateFee()
    }
    
    @IBAction func onTimeLockSwitchToggle(_ sender: Any) {
        timeLockEnabled = !timeLockEnabled
        updateFee()
    }
    
    @IBAction func datePickerChanged(_ sender: Any) {
        updateFee()
    }

    @IBAction func send() {
        guard let address = addressTextField?.text else {
            return
        }

        do {
            try currentAdapter?.validate(address: address)
        } catch {
            show(error: "Invalid address")
            return
        }

        guard let amountString = amountTextField?.text, let amount = Decimal(string: amountString) else {
            show(error: "Invalid amount")
            return
        }
        
        var pluginData = [String: [String: Any]]()
        if let lockUntil = datePicker?.date, timeLockEnabled {
            pluginData["hodler"] = ["locked_until": Int(lockUntil.timeIntervalSince1970)]
        }

        currentAdapter?.sendSingle(to: address, amount: amount, pluginData: pluginData)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] _ in
                    self?.addressTextField?.text = ""
                    self?.amountTextField?.text = ""

                    self?.showSuccess(address: address, amount: amount)
                }, onError: { [weak self] error in
                    self?.show(error: "Send failed: \(error)")
                })
                .disposed(by: disposeBag)
    }

    private func show(error: String) {
        let alert = UIAlertController(title: "Send Error", message: error, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }

    private func showSuccess(address: String, amount: Decimal) {
        let alert = UIAlertController(title: "Success", message: "\(amount.description) sent to \(address)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }

    private var currentAdapter: BaseAdapter? {
        guard segmentedControl.selectedSegmentIndex != -1, adapters.count > segmentedControl.selectedSegmentIndex else {
            return nil
        }

        return adapters[segmentedControl.selectedSegmentIndex]
    }

}
