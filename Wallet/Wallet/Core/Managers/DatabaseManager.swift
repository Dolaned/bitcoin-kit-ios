import Foundation
import RxSwift
import RealmSwift
import RxRealm

class DatabaseManager: IDatabaseManager {
    private let realm = Factory.instance.realmManager.createWalletRealm()

    func getBitcoinUnspentOutputs() -> Observable<DatabaseChangeSet<BitcoinUnspentOutput>> {
        return Observable.arrayWithChangeset(from: realm.objects(BitcoinUnspentOutput.self))
                .map { DatabaseChangeSet(array: $0, changeSet: $1.map { CollectionChangeSet(withRealmChangeset: $0) }) }
    }

    func getBitcoinCashUnspentOutputs() -> Observable<DatabaseChangeSet<BitcoinCashUnspentOutput>> {
        return Observable.arrayWithChangeset(from: realm.objects(BitcoinCashUnspentOutput.self))
                .map { DatabaseChangeSet(array: $0, changeSet: $1.map { CollectionChangeSet(withRealmChangeset: $0) }) }
    }

    func getExchangeRates() -> Observable<DatabaseChangeSet<ExchangeRate>> {
        return Observable.arrayWithChangeset(from: realm.objects(ExchangeRate.self))
                .map { DatabaseChangeSet(array: $0, changeSet: $1.map { CollectionChangeSet(withRealmChangeset: $0) }) }
    }

    func getTransactionRecords() -> Observable<DatabaseChangeSet<TransactionRecord>> {
        return Observable.arrayWithChangeset(from: realm.objects(TransactionRecord.self).sorted(byKeyPath: "blockHeight", ascending: false))
                .map { DatabaseChangeSet(array: $0, changeSet: $1.map { CollectionChangeSet(withRealmChangeset: $0) }) }
    }

}