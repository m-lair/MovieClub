//
//  ComingSoonRowView.swift
//  MovieClub
//
//  Created by Marcus Lair on 8/16/24.
//

import SwiftUI

struct ComingSoonRowView: View {
    @Environment(DataManager.self) private var data
    @State var member: Member
    @State var imageUrl: String? = ""
    var body: some View {
        let _ = print("in row view")
        HStack{
            CircularImageView(userId: member.userId, size: 30)
            Text("\(member.userName)")
        }
    }
}
