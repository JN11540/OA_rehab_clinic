import Foundation

// MARK: - Exercise Samples
extension ExerciseModule.Exercise {
    // 移除 stableUUID 函數，直接使用 UUID()
    
    // 所有樣本動作組合為一個合集 (移除臀部肌群)
    public static var allSamples: [ExerciseModule.Exercise] {
        return quadricepsBasic + quadricepsIntermediate + quadricepsAdvanced +
               flexibilityBasic + proprioception
    }
    
    // 根據名稱查找範例動作
    public static func findSample(by name: String, category: String? = nil) -> ExerciseModule.Exercise? {
        return allSamples.first { 
            $0.name == name && (category == nil || $0.category == category) 
        }
    }
    
    // 股四頭肌肌力訓練 - 初階
    public static let quadricepsBasic: [ExerciseModule.Exercise] = [
        ExerciseModule.Exercise(
            id: UUID(),
            name: "股四頭肌等長收縮",
            englishName: "Isometric quadriceps set",
            imageName: "1.股四頭肌等長收縮",
            category: "股四頭肌肌力訓練",
            level: "初階",
            description: "將患側腿伸直放於水平面。接著使股四頭肌緊收用力伸直膝蓋，將膝蓋後側向下壓。",
            difficulty: "能連續完成3組每組15下，且動作能平順完成佳。"
        ),
        ExerciseModule.Exercise(
            id: UUID(),
            name: "膝關節終端伸展",
            englishName: "Terminal knee extension",
            imageName: "2.膝關節終端伸展",
            category: "股四頭肌肌力訓練",
            level: "初階",
            description: "以坐姿雙腳踩地，股四頭肌出力將患側腳抬起，盡量將膝關節打直並維持。",
            difficulty: "能連續完成3組每組15下，且動作能平順完成佳。"
        ),
        ExerciseModule.Exercise(
            id: UUID(),
            name: "躺姿抬腿",
            englishName: "Straight-leg raise (lying)",
            imageName: "3.躺姿抬腿",
            category: "股四頭肌肌力訓練",
            level: "初階",
            description: "躺在地面上，膝關節由彎曲狀態下漸漸伸直，抬高並維持姿勢。",
            difficulty: "能連續完成3組每組15下，且動作能平順完成佳。"
        ),
        ExerciseModule.Exercise(
            id: UUID(),
            name: "俯臥抬腿",
            englishName: "Prone Single Leg Lift",
            imageName: "4.俯臥抬腿",
            category: "股四頭肌肌力訓練",
            level: "初階",
            description: "以躺姿彎曲單側膝蓋，將另一側腿伸直並緩慢抬起，維持五秒後放下。",
            difficulty: "能夠連續完成3組每組10下，且動作平順度佳，膝關節維持良好位置。"
        ),
        ExerciseModule.Exercise(
            id: UUID(),
            name: "側躺抬腿（外展）",
            englishName: "Side-lying leg lift (Eccentric)",
            imageName: "5.側躺抬腿（外展）",
            category: "股四頭肌肌力訓練",
            level: "初階",
            description: "側躺保持平衡，將上側腿保持伸直抬離地面，使用臀部外側肌群出力，再緩慢放下。",
            difficulty: "能連續完成3組每組10下，且動作能平順完成佳。"
        ),
        ExerciseModule.Exercise(
            id: UUID(),
            name: "側躺抬腿（內收）",
            englishName: "Side-lying leg lift (cross over)",
            imageName: "6.側躺抬腿（內收）",
            category: "股四頭肌肌力訓練",
            level: "初階",
            description: "側躺將上側腿彎曲放於下側腿前側，將下側腿保持伸直抬離地面，使用臀部內側肌群出力，再緩慢放下。",
            difficulty: "能夠連續完成3組每組10下，且動作平順度佳。"
        )
    ]
    
    // 股四頭肌肌力訓練 - 中階
    public static let quadricepsIntermediate: [ExerciseModule.Exercise] = [
        ExerciseModule.Exercise(
            id: UUID(),
            name: "負重膝關節終端伸展",
            englishName: "Terminal knee extension with cuff weights",
            imageName: "7.負重膝關節終端伸展",
            category: "股四頭肌肌力訓練",
            level: "中階",
            description: "將患側的腳踝綁上重物，以坐姿雙腳踩地，股四頭肌出力將患側腳抬起，盡量將膝關節打直並維持。",
            difficulty: "能夠連續完成3組每組15下，且動作平順程度佳。"
        ),
        ExerciseModule.Exercise(
            id: UUID(),
            name: "站立膝關節終端伸展",
            englishName: "Terminal knee extension in standing with resistive band",
            imageName: "8.站立膝關節終端伸展",
            category: "股四頭肌肌力訓練",
            level: "中階",
            description: "站姿膝關節彎曲約45度，前方手扶穩定的椅背支撐，透過股四頭肌出力將患側腳膝蓋打直並維持。",
            difficulty: "能連續完成3組每組15下，且動作能平順完成佳(也可以透過增加彈力帶阻力及移除椅子支撐來調整)。"
        ),
        ExerciseModule.Exercise(
            id: UUID(),
            name: "部分蹲",
            englishName: "Weight-reduced partial squats",
            imageName: "9.部分蹲",
            category: "股四頭肌肌力訓練",
            level: "中階",
            description: "站姿使膝關節伸直，前方手扶穩定的椅背支撐，慢速下將膝關節彎曲至45度並維持。",
            difficulty: "能連續完成3組每組15下，且動作能平順完成佳（也可以透過移除椅子支撐來調整）。"
        ),
        ExerciseModule.Exercise(
            id: UUID(),
            name: "橋式",
            englishName: "Bridge",
            imageName: "10.橋式",
            category: "股四頭肌肌力訓練",
            level: "中階",
            description: "平躺雙腳屈膝，將臀部抬起使身體呈一直線，再緩慢回到平躺姿勢。",
            difficulty: "能夠連續完成3組每組10下，且動作平順度佳，一日3次。"
        ),
        ExerciseModule.Exercise(
            id: UUID(),
            name: "大腿內夾運動",
            englishName: "Inner thigh squeeze with ball",
            imageName: "11.大腿內夾運動",
            category: "股四頭肌肌力訓練",
            level: "中階",
            description: "坐在椅子上，將球夾在大腿之間，緊縮大腿肌肉。",
            difficulty: "能連續完成3組每組15下，且動作能平順完成佳。"
        )
    ]
    
    // 股四頭肌肌力訓練 - 高階
    public static let quadricepsAdvanced: [ExerciseModule.Exercise] = [
        ExerciseModule.Exercise(
            id: UUID(),
            name: "登階運動",
            englishName: "Step Training",
            imageName: "12.登階運動",
            category: "股四頭肌肌力訓練",
            level: "高階",
            description: "站姿前方放置小台階或樓梯，以慢速將患側腳踏上階梯，雙腳均站上台階使膝蓋打直，再使用患側腳向後下階梯回到起始位置。",
            difficulty: "可透過增加台階高度，或增加跨越的階梯數目來微調難度。"
        ),
        ExerciseModule.Exercise(
            id: UUID(),
            name: "靠牆深蹲",
            englishName: "Wall squats",
            imageName: "13.靠牆深蹲",
            category: "股四頭肌肌力訓練",
            level: "高階",
            description: "採站姿身體背部貼於牆面，沿牆壁緩慢下降，蹲下直到膝蓋呈現90度，再回復站姿。",
            difficulty: "能夠連續完成3組每組10下，且動作平順度佳，一日3次。"
        )
    ]
    
    // 柔軟度訓練 (移除階層分類)
    public static let flexibilityBasic: [ExerciseModule.Exercise] = [
        ExerciseModule.Exercise(
            id: UUID(),
            name: "大腿後側肌群伸展",
            englishName: "Hamstring stretch",
            imageName: "14.大腿後側肌群伸展（一）",
            category: "柔軟度訓練",
            level: "無分階",
            description: "坐於椅子將患側腳伸直，雙手放於腿上身體前彎並於極限時維持。",
            difficulty: "動作開始後30秒視為結束，在過程中需持續監測受試者的膝關節有無時刻保持完全伸直，若無則一樣不能視為完成動作。"
        ),
        ExerciseModule.Exercise(
            id: UUID(),
            name: "大腿後側肌群伸展",
            englishName: "Hamstring stretch",
            imageName: "15.大腿後側肌群伸展（二）",
            category: "柔軟度訓練",
            level: "無分階",
            description: "坐於地面將患側腳伸直，雙手放於腿上身體前彎並於極限時維持。",
            difficulty: "動作開始後30秒視為結束，在過程中需持續監測受試者的膝關節有無時刻保持完全伸直，若無則不能視為完成動作。"
        ),
        ExerciseModule.Exercise(
            id: UUID(),
            name: "股四頭肌伸展",
            englishName: "Quadriceps stretch",
            imageName: "16.股四頭肌伸展（一）",
            category: "柔軟度訓練",
            level: "無分階",
            description: "趴姿以健側腳勾住患側腳往骨盆下壓並於極限時維持。",
            difficulty: "當膝關節屈曲達到120度或以上時開始計時，持續維持30秒視為動作完成。"
        ),
        ExerciseModule.Exercise(
            id: UUID(),
            name: "股四頭肌伸展",
            englishName: "Quadriceps stretch",
            imageName: "17.股四頭肌伸展（二）",
            category: "柔軟度訓練",
            level: "無分階",
            description: "側躺使患側腳在上，用同側手勾住患側腳往骨盆方向壓並於極限時維持。",
            difficulty: "當膝關節屈曲達到140度或以上時開始計時，持續維持30秒視為動作完成。"
        ),
        ExerciseModule.Exercise(
            id: UUID(),
            name: "小腿後肌肉伸展",
            englishName: "Calf stretch",
            imageName: "18.小腿後肌肉伸展（一）",
            category: "柔軟度訓練",
            level: "無分階",
            description: "以患側腳在後做弓箭步姿勢，彎曲健側腳使身體重心前移並於極限時維持。",
            difficulty: "動作開始後30秒視為結束，在過程中需持續監測受試者的膝關節有無時刻保持完全伸直。"
        ),
        ExerciseModule.Exercise(
            id: UUID(),
            name: "小腿後肌肉伸展",
            englishName: "Calf stretch",
            imageName: "19.小腿後肌肉伸展（二）",
            category: "柔軟度訓練",
            level: "無分階",
            description: "以腳尖踮腳站於階梯邊緣，將腳踝向下直到背屈到極限時維持。",
            difficulty: "動作開始後30秒視為結束，在過程中需持續監測受試者的膝關節有無時刻保持完全伸直。"
        )
    ]
    
    // 膝關節本體感覺訓練 - 高階
    public static let proprioception: [ExerciseModule.Exercise] = [
        ExerciseModule.Exercise(
            id: UUID(),
            name: "前後滑行運動",
            englishName: "Slide-exercise forward-backward, opened eyes",
            imageName: "20.前後滑行運動",
            category: "膝關節本體感覺訓練",
            level: "高階",
            description: "站姿可單手側面扶牆或椅背，將健側腳向前滑行，患側腳微彎承重，再慢慢回到站姿。",
            difficulty: "能夠連續完成3組每組15下，且動作平順度佳，膝關節維持良好位置。"
        ),
        ExerciseModule.Exercise(
            id: UUID(),
            name: "側向滑行運動",
            englishName: "Slide-exercise sideways, opened eyes",
            imageName: "21.側向滑行運動",
            category: "膝關節本體感覺訓練",
            level: "高階",
            description: "站姿可雙手正面扶牆或椅背，將健側腳向外滑行，患側腳微彎承重，再慢慢回到站姿。",
            difficulty: "能夠連續完成3組每組15下，且動作平順度佳，膝關節維持良好位置。"
        ),
        ExerciseModule.Exercise(
            id: UUID(),
            name: "前跨步弓步蹲",
            englishName: "Forward lunge, opened eyes",
            imageName: "22.前跨步弓步蹲",
            category: "膝關節本體感覺訓練",
            level: "高階",
            description: "站姿可單手側面扶牆或椅背，將健側腳向前跨步，患側腳膝蓋向地面彎曲，再慢慢回到站姿。",
            difficulty: "能夠連續完成3組每組15下，且動作平順度佳，膝關節維持良好位置。"
        )
    ]
}

// MARK: - Category Samples
extension ExerciseModule.ExerciseCategory {
    public static let samples: [ExerciseModule.ExerciseCategory] = [
        ExerciseModule.ExerciseCategory(
            name: "股四頭肌肌力訓練",
            subcategories: [
                ExerciseModule.ExerciseSubcategory(
                    name: "初階",
                    exercises: ExerciseModule.Exercise.quadricepsBasic
                ),
                ExerciseModule.ExerciseSubcategory(
                    name: "中階",
                    exercises: ExerciseModule.Exercise.quadricepsIntermediate
                ),
                ExerciseModule.ExerciseSubcategory(
                    name: "高階",
                    exercises: ExerciseModule.Exercise.quadricepsAdvanced
                )
            ]
        ),
        ExerciseModule.ExerciseCategory(
            name: "柔軟度訓練",
            subcategories: [
                ExerciseModule.ExerciseSubcategory(
                    name: "無分階",
                    exercises: ExerciseModule.Exercise.flexibilityBasic
                )
            ]
        ),
        ExerciseModule.ExerciseCategory(
            name: "膝關節本體感覺訓練",
            subcategories: [
                ExerciseModule.ExerciseSubcategory(
                    name: "高階",
                    exercises: ExerciseModule.Exercise.proprioception
                )
            ]
        )
    ]
} 
